import { createClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseKey = import.meta.env.VITE_SUPABASE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.warn(
    "Не заданы переменные VITE_SUPABASE_URL и VITE_SUPABASE_KEY. Укажите их в .env.local."
  );
}

export const supabase = createClient(
  supabaseUrl || "https://demo.supabase.co",
  supabaseKey || "public-anon-key"
);
