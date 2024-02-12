import { createClient } from "@supabase/supabase-js";

export const supabase = createClient(
  "https://hpoalcgmrnautftiqirm.supabase.co",
  "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhwb2FsY2dtcm5hdXRmdGlxaXJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDc3Njg3MjQsImV4cCI6MjAyMzM0NDcyNH0._9lxGZer53uFHLqlNQMcmvuSwB6vXIHpOhDmLUfGVMg"
);
