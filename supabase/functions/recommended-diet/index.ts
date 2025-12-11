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
    let { recommended_calories, special_conditions, allergies } = body;

    if (Array.isArray(special_conditions)) {
      if (special_conditions.includes("No Any")) {
        special_conditions = []; 
      }
    }

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

  const noRestrictions = !special_conditions || !Array.isArray(special_conditions) || special_conditions.length === 0;

  const seed = Math.floor(Math.random() * 1000000);

   const userPrompt = `
    RANDOM VARIATION SEED: ${seed}
    You are a nutritionist generating diverse meal plans. Follow restrictions but prioritize meal variety.

    CRITICAL DIETARY RESTRICTIONS:
    ${ noRestrictions ? "None" : special_conditions.map((req: string, i: number) => `${i+1}. ${req}`).join("\n") }

    ${allergies && allergies !== "none" ? `ALLERGIES TO AVOID: ${allergies}\n` : ''}

    /* IMPORTANT INSTRUCTIONS - READ CAREFULLY */
    1) When there are NO special conditions, provide a normal balanced diet including meat, poultry, fish, vegetables, grains and dairy as appropriate.
    2) If Vegetarian or Vegan is selected, strictly comply (no animal products for Vegan; no meat/fish for Vegetarian).
    3) If "Diabetes" is selected: Meat is available. Low glycemic index foods, no added sugars, complex carbs only. 
    4) If "Halal" is selected: Meat is available. But only halal-certified foods, no pork, no alcohol.
    5) If "Indian" is selected: Meat is available. Include Indian cuisine options, ensure no beef.
    6) If "High Blood Pressure" is selected: Meat is available.Low sodium, no processed foods.
    7) If "High Cholesterol" is selected: Meat is available. Make sure diet is low saturated fat.
    8) **Do NOT use fixed macro templates (e.g., do NOT always output 250g carbs or 70g fat).**
    9) **Compute macros from the foods and portion sizes you list.** The macro numbers must reflect the foods (e.g., if you include 150g grilled chicken, protein should increase accordingly).
    10) **Vary proteins and main dishes** across plans — do not always select grilled chicken or salmon. Prefer rotation: chicken, fish, beef, tofu, eggs, tempeh, mackerel, etc., and include Malaysian dishes where applicable.
    11) Aim the TOTAL DAILY CALORIES close to ${recommended_calories} kcal (allow natural variation within roughly ±15%). Do not force the number exactly; estimate based on portions chosen.
    12) Avoid repeating the same macro numbers and same protein sources in consecutive responses.
    13) Return ONLY valid JSON (no explanation, no extra text).
    /* VARIATION POLICY - MUST FOLLOW */
    14) Rotate meal ideas every time. Do NOT repeat the same protein sources or dishes across different outputs. 
    15) MUST pick different breakfast, lunch, and dinner options each call. Use wide variety:
        - Breakfast: nasi lemak (light), roti canai (low oil), oats, sandwiches, smoothies, yogurt bowls, mee hoon soup, etc.
        - Lunch: stir-fried beef, ayam masak merah, curry laksa (light), sushi, teriyaki chicken, nasi kerabu, tofu bowls.
        - Dinner: steamed seabass, grilled lamb, pasta, chapati sets, tom yum (light), tofu stir fry, curry chickpeas, etc.
    16) Vary portion sizes, cuisines, and protein sources.
    17) You MUST avoid meal templates seen in previous outputs. Use new, creative, but realistic Malaysian or general meals.

    Now produce a single JSON object exactly in this structure. For numeric fields, give realistic rounded values that are consistent with the meal descriptions and with each other:

    {
      "daily_calories": <estimated_total_calories_based_on_meals>,
      "carbs": <grams_estimated_from_foods>,
      "protein": <grams_estimated_from_foods>,
      "fat": <grams_estimated_from_foods>,
      "breakfast": "<detailed meal description with portions, e.g., '2 eggs, 1 slice wholegrain toast, 100g mixed fruit, 1 tsp butter'>",
      "lunch": "<detailed meal description with portions>",
      "dinner": "<detailed meal description with portions>",
      "summary": "<2-3 sentence summary explaining how the plan matches restrictions and estimated macros>"
    }

    VERIFY: Before returning, check that macros numerically match the foods and that the daily_calories is the sum of meal estimates. Do NOT output macro values that are identical to typical fixed templates (e.g., 250/70/120) unless the foods legitimately produce those numbers.
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
            temperature: 1.0,
            top_p: 1.0,
            response_format: { type: "json_object" },
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