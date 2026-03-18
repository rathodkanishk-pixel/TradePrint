// ═══════════════════════════════════════════════════════════
//  TRADEPRINT — SUPABASE CONFIGURATION
//  
//  STEP 1: Go to https://supabase.com and create a free account
//  STEP 2: Create a new project
//  STEP 3: Go to Settings → API
//  STEP 4: Copy your "Project URL" and paste it below
//  STEP 5: Copy your "anon public" key and paste it below
//  
//  That's it. Save this file and your website will work.
// ═══════════════════════════════════════════════════════════

const SUPABASE_URL = https://mtoyckxekmzpalvajheh.supabase.co
const SUPABASE_ANON_KEY = eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im10b3lja3hla216cGFsdmFqaGVoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzM4MzY4MjgsImV4cCI6MjA4OTQxMjgyOH0.emu173blpsNV2BMWipylsuW-NxuWK77vGPQib7HZOMk

// DO NOT change anything below this line
window.supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
