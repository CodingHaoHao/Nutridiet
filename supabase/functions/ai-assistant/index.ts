import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response(JSON.stringify({ error: "POST only" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const userMessage = body.message ?? "";
    const imageBase64 = body.imageBase64 ?? null;
    const history = body.history ?? [];

    const nutritionKeywords = [
      "calorie", "calories", "protein", "carbohydrate", "fat", "vitamin", "nutrition",
      "meal", "food", "diet", "health", "bmr", "tdee", "weight", "lose weight",
      "gain weight", "nutrient", "sugar", "cholesterol", "fiber", "macronutrient",
      "micronutrient", "water", "balanced diet", "metabolism", "vegetarian",
      "allergy", "recipe", "intake", "dietary", "nutritionist", "dietitian"
    ];

    const isNutritionRelated = nutritionKeywords.some(keyword =>
      userMessage.toLowerCase().includes(keyword)
    );

    if (!isNutritionRelated && !imageBase64) {
      return new Response(
        JSON.stringify({ assistant: "Only nutrition-related questions are allowed." }),
        { status: 200, headers: { "Content-Type": "application/json" } }
      );
    }

    const OPENAI_API_KEY = Deno.env.get("OPENAI_API_KEY");
    if (!OPENAI_API_KEY) {
      return new Response(
        JSON.stringify({ error: "OPENAI_API_KEY not configured" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    // text or image content
    const userContent: any[] = [];

    if (userMessage) {
      userContent.push({ type: "text", text: userMessage });
    }

    if (imageBase64) {
      userContent.push({
        type: "image_url",
        image_url: {
          url: `data:image/jpeg;base64,${imageBase64}`,
        },
      });
    }

    const systemInstruction = {
    role: "system",
    content: [
      {
        type: "text",
        text: `
          You are a professional AI nutrition assistant in the NutriDiet application.
          Your main goal is to respond to nutrition-related user questions and analyze food images.
          Only answer questions straight to the point with accurate information.

          If the user sends a food image, analyze its contents and respond with this format:

          Food Name: 
          Calories: 
          Carbohydrates: 
          Protein: 
          Fat: 

          Then give the total nutrition information:
          Total Calories:
          Total Carbohydrates:
          Total Protein:
          Total Fat:
          
          Summary: 
          (Provide a brief summary of the food, how is the food for user health. 
          Is it a suitable meal? Is it good for health or any recommendations for improvement.)

          If the user provides multiple foods, list each one in the same structured format. Then list a total nutrition information.
          Avoid adding unrelated text or explanations. Do not put many structure format like bold, ### or other, just follow my format above to show in clear way for user easy to read.
          `,
        },
      ],
    };

    const payload = {
      model: "gpt-4o-mini",
      messages: [
        systemInstruction,  
        ...history,
        { role: "user", content: userContent },
      ],
      max_tokens: 1000,
    };

    const openaiRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
      },
      body: JSON.stringify(payload),
    });

    const data = await openaiRes.json();

    if (!openaiRes.ok) {
      return new Response(JSON.stringify({ error: data }), {
        status: openaiRes.status,
        headers: { "Content-Type": "application/json" },
      });
    }

    const assistantText =
      data?.choices?.[0]?.message?.content ??
      data?.choices?.[0]?.text ??
      "No response from model.";

    return new Response(JSON.stringify({ assistant: assistantText }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });

  } catch (err) {
    return new Response(JSON.stringify({ error: (err as Error).message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
