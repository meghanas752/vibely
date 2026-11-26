-- =========================================
-- VIBELY: SEED DATA + REALTIME
-- =========================================

insert into public.questions (id, text, options) values
(1,  'How do you like to spend your weekends?',
     '["Out with friends", "Quiet time at home", "Outdoors or travelling", "A bit of everything"]'),
(2,  'Do you want children someday?',
     '["Yes", "No", "Not sure yet"]'),
(3,  'How do you feel about drinking?',
     '["I don''t drink", "Socially", "Regularly"]'),
(4,  'How do you feel about smoking?',
     '["I don''t smoke", "Occasionally", "Regularly"]'),
(5,  'What are your food habits?',
     '["Vegetarian", "Eggetarian", "Non-vegetarian", "Vegan"]'),
(6,  'How do you handle disagreements?',
     '["Talk it out right away", "Need some time, then talk", "Prefer to avoid conflict"]'),
(7,  'What role should family play in your relationship decisions?',
     '["Very involved", "Consulted, but I decide", "Fully my own decision"]'),
(8,  'Would you relocate to another city for a partner?',
     '["Yes", "Maybe", "No"]'),
(9,  'How do you prefer to stay in touch while dating?',
     '["Texting through the day", "A few check-ins", "Calls over texts"]'),
(10, 'How important is career ambition in a partner?',
     '["Very important", "Somewhat important", "Not important"]');

-- Turn on real-time updates for chat messages
alter publication supabase_realtime add table public.messages;