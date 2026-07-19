-- Clear existing chat histories in AI_Summary table to free space and protect privacy, keeping only the symptom summaries
UPDATE dbo.AI_Summary
SET chat_history = NULL;
