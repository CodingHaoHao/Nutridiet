// supabase/functions/recommended-diet/index.ts
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

serve(async (request: Request) => {
  try {
    // CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
      });
    }

    if (request.method !== "POST") {
      return new Response(
        JSON.stringify({ error: "Only POST requests are allowed." }),
        { 
          status: 405,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    const body = await request.json();
    const { recommended_calories, special_conditions, allergies } = body;

    if (!recommended_calories) {
      return new Response(
        JSON.stringify({ error: "Missing required field: recommended_calories" }),
        { 
          status: 400,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
    if (!OPENAI_API_KEY) {
      return new Response(
        JSON.stringify({ error: "OPENAI_API_KEY not configured" }),
        { 
          status: 500,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    // Build requirements list
    const requirementsList = special_conditions && Array.isArray(special_conditions) && special_conditions.length > 0
      ? special_conditions.join(", ")
      : "none";

    // Create a very strict prompt that emphasizes the dietary restrictions
    const userPrompt = `
    You are a professional nutritionist. Create a diet plan that STRICTLY follows these requirements:

    CRITICAL DIETARY RESTRICTIONS (MUST BE FOLLOWED):
    ${special_conditions && Array.isArray(special_conditions) && special_conditions.length > 0 
      ? special_conditions.map((req: string, index: number) => `${index + 1}. ${req}`).join('\n')
      : 'None'}

    ${allergies && allergies !== "none" ? `ALLERGIES TO AVOID (ABSOLUTELY NO): ${allergies}` : ''}

    IMPORTANT RULES:
    - If "Vegetarian" is selected: NO meat, NO poultry, NO fish, NO seafood
    - If "Vegan" is selected: NO animal products at all (no meat, fish, dairy, eggs, honey)
    - If "Diabetes" is selected: Meat is available. Low glycemic index foods, no added sugars, complex carbs only
    - If "Halal" is selected: Meat is available. But only halal-certified foods, no pork, no alcohol
    - If "High Blood Pressure" is selected: Meat is available.Low sodium, no processed foods
    - If "High Cholesterol" is selected: Meat is available. Make sure diet is low saturated fat,
    - If "No Any" is selected: NO dietary restrictions, provide a normal balanced diet with variety of foods including meat, fish, vegetables, grains

    Target Daily Calories: <=${recommended_calories} kcal

    Provide a JSON response with this EXACT structure:
    {
      "daily_calories": <=${recommended_calories},
      "carbs": <number in grams>,
      "protein": <number in grams>,
      "fat": <number in grams>,
      "breakfast": "<meal description with specific foods and portions>",
      "lunch": "<meal description with specific foods and portions>",
      "dinner": "<meal description with specific foods and portions>",
      "summary": "<2-3 sentence summary explaining how this plan meets the dietary restrictions>"
    }

    VERIFY: Before responding, double-check that ALL meals comply with EVERY dietary restriction listed above.
    Return ONLY valid JSON, no markdown, no additional text.
    `;

    const openaiRes = await fetch(
      "https://api.openai.com/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: "gpt-4o-mini",
          messages: [
            {
              role: "system",
              content: "You are a strict professional nutritionist. You MUST follow all dietary restrictions without exception. Never suggest foods that violate the user's dietary conditions. If someone is vegetarian or vegan, absolutely NO animal products in those categories. Respond ONLY in valid JSON format.",
            },
            {
              role: "user",
              content: userPrompt,
            },
          ],
          response_format: { type: "json_object" },
          temperature: 0.3, // Lower temperature for more consistent, rule-following responses
        }),
      }
    );

    if (!openaiRes.ok) {
      return new Response(
        JSON.stringify({ error: "OpenAI request failed", details: err }),
        { 
          status: 500,
          headers: {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          },
        }
      );
    }

    const result = await openaiRes.json();

    const output =
      result.choices?.[0]?.message?.content
        ? JSON.parse(result.choices[0].message.content)
        : { error: "Invalid response from model" };

    return new Response(JSON.stringify(output), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });

  } catch (error) {
    return new Response(
      JSON.stringify({ 
        error: "Server error", 
        details: error instanceof Error ? error.message : String(error)
      }),
      { 
        status: 500,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        },
      }
    );
  }
});