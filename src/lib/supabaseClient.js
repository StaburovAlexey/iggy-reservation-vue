import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.VUE_APP_SUPABASE_URL;
const supabaseKey = process.env.VUE_APP_SUPABASE_KEY;
if (!supabaseUrl || !supabaseKey) {
  console.warn(
    "Не заданы переменные VUE_APP_SUPABASE_URL и VUE_APP_SUPABASE_KEY. Укажите их в .env.local."
  );
}

export const supabase = createClient(
  supabaseUrl || "https://demo.supabase.co",
  supabaseKey || "public-anon-key"
);
