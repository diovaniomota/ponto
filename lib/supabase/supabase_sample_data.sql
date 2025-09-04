CREATE OR REPLACE FUNCTION insert_user_to_auth(
    email text,
    password text
) RETURNS UUID AS $$
DECLARE
  user_id uuid;
  encrypted_pw text;
BEGIN
  user_id := gen_random_uuid();
  encrypted_pw := crypt(password, gen_salt('bf'));
  
  INSERT INTO auth.users
    (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, recovery_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token)
  VALUES
    (gen_random_uuid(), user_id, 'authenticated', 'authenticated', email, encrypted_pw, '2023-05-03 19:41:43.585805+00', '2023-04-22 13:10:03.275387+00', '2023-04-22 13:10:31.458239+00', '{"provider":"email","providers":["email"]}', '{}', '2023-05-03 19:41:43.580424+00', '2023-05-03 19:41:43.585948+00', '', '', '', '');
  
  INSERT INTO auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  VALUES
    (gen_random_uuid(), user_id, format('{"sub":"%s","email":"%s"}', user_id::text, email)::jsonb, 'email', '2023-05-03 19:41:43.582456+00', '2023-05-03 19:41:43.582497+00', '2023-05-03 19:41:43.582497+00');
  
  RETURN user_id;
END;
$$ LANGUAGE plpgsql;


-- Insert sample users into auth.users and then into the public.users table
SELECT insert_user_to_auth('john.doe@example.com', 'password123');
SELECT insert_user_to_auth('jane.smith@example.com', 'password123');
SELECT insert_user_to_auth('bob.johnson@example.com', 'password123');

INSERT INTO public.users (id, email, full_name, avatar_url, created_at, updated_at)
SELECT
  auth.uid(),
  'john.doe@example.com',
  'John Doe',
  'https://example.com/avatars/john.jpg',
  NOW() - INTERVAL '3 months',
  NOW() - INTERVAL '1 month'
FROM auth.users
WHERE email = 'john.doe@example.com';

INSERT INTO public.users (id, email, full_name, avatar_url, created_at, updated_at)
SELECT
  auth.uid(),
  'jane.smith@example.com',
  'Jane Smith',
  'https://example.com/avatars/jane.jpg',
  NOW() - INTERVAL '2 months',
  NOW() - INTERVAL '2 weeks'
FROM auth.users
WHERE email = 'jane.smith@example.com';

INSERT INTO public.users (id, email, full_name, avatar_url, created_at, updated_at)
SELECT
  auth.uid(),
  'bob.johnson@example.com',
  'Bob Johnson',
  'https://example.com/avatars/bob.jpg',
  NOW() - INTERVAL '1 month',
  NOW() - INTERVAL '1 week'
FROM auth.users
WHERE email = 'bob.johnson@example.com';

-- Insert sample projects
INSERT INTO public.projects (user_id, title, description, status, due_date, priority, created_at, updated_at)
SELECT
  (SELECT id FROM public.users WHERE email = 'john.doe@example.com'),
  'Website Redesign',
  'Redesign the company website for better user experience and modern aesthetics.',
  'active',
  NOW() + INTERVAL '2 months',
  'high',
  NOW() - INTERVAL '2 months',
  NOW() - INTERVAL '1 week';

INSERT INTO public.projects (user_id, title, description, status, due_date, priority, created_at, updated_at)
SELECT
  (SELECT id FROM public.users WHERE email = 'john.doe@example.com'),
  'Mobile App Development',
  'Develop a new mobile application for iOS and Android platforms.',
  'active',
  NOW() + INTERVAL '4 months',
  'high',
  NOW() - INTERVAL '1 month',
  NOW() - INTERVAL '3 days';

INSERT INTO public.projects (user_id, title, description, status, due_date, priority, created_at, updated_at)
SELECT
  (SELECT id FROM public.users WHERE email = 'jane.smith@example.com'),
  'Marketing Campaign Launch',
  'Plan and execute a new marketing campaign for the upcoming product launch.',
  'active',
  NOW() + INTERVAL '1 month',
  'medium',
  NOW() - INTERVAL '3 weeks',
  NOW() - INTERVAL '2 days';

INSERT INTO public.projects (user_id, title, description, status, due_date, priority, created_at, updated_at)
SELECT
  (SELECT id FROM public.users WHERE email = 'jane.smith@example.com'),
  'Internal Tool Development',
  'Build an internal tool to streamline team workflows.',
  'completed',
  NOW() - INTERVAL '1 week',
  'low',
  NOW() - INTERVAL '2 months',
  NOW() - INTERVAL '1 week';

INSERT INTO public.projects (user_id, title, description, status, due_date, priority, created_at, updated_at)
SELECT
  (SELECT id FROM public.users WHERE email = 'bob.johnson@example.com'),
  'Database Optimization',
  'Optimize database queries and structure for improved performance.',
  'active',
  NOW() + INTERVAL '3 weeks',
  'high',
  NOW() - INTERVAL '1 month',
  NOW() - INTERVAL '4 days';

-- Insert sample tasks
INSERT INTO public.tasks (project_id, user_id, title, description, is_completed, due_date, priority, created_at, updated_at)
SELECT
  (SELECT id FROM public.projects WHERE title = 'Website Redesign' AND user_id = (SELECT id FROM public.users WHERE email = 'john.doe@example.com')),
  (SELECT id FROM public.users WHERE email = 'john.doe@example.com'),
  'Design Homepage Mockups',
  'Create initial mockups for the website homepage.',
  false,
  NOW() + INTERVAL '3 weeks',
  'high',
  NOW() - INTERVAL '1 month',
  NOW() - INTERVAL '2 days';

INSERT INTO public.tasks (project_id, user_id, title, description, is_completed, due_date, priority, created_at, updated_at)
SELECT
  (SELECT id FROM public.projects WHERE title = 'Website Redesign' AND user_id = (SELECT id FROM public.users WHERE email = 'john.doe@example.com')),
  (SELECT id FROM public.users WHERE email = 'john.doe@example.com'),
  'Develop Frontend Components',
  'Implement reusable React components for the new design.',
  false,
  NOW() + INTERVAL '6 weeks',
  'medium',
  NOW() - INTERVAL '3 weeks',
  NOW() - INTERVAL '1 day';

INSERT INTO public.tasks (project_id, user_id, title, description, is_completed, due_date, priority, created_at, updated_at)
SELECT
  (SELECT id FROM public.projects WHERE title = 'Mobile App Development' AND user_id = (SELECT id FROM public.users WHERE email = 'john.doe@example.com')),
  (SELECT id FROM public.users WHERE email = 'john.doe@example.com'),
  'API Integration',
  'Integrate the mobile app with the backend API.',
  false,
  NOW() + INTERVAL '2 months',
  'high',
  NOW() - INTERVAL '2 weeks',
  NOW() - INTERVAL '12 hours';

INSERT INTO public.tasks (project_id, user_id, title, description, is_completed, due_date, priority, created_at, updated_at)
SELECT
  (SELECT id FROM public.projects WHERE title = 'Marketing Campaign Launch' AND user_id = (SELECT id FROM public.users WHERE email = 'jane.smith@example.com')),
  (SELECT id FROM public.users WHERE email = 'jane.smith@example.com'),
  'Create Social Media Content',
  'Develop engaging content for various social media platforms.',
  true,
  NOW() - INTERVAL '1 week',
  'medium',
  NOW() - INTERVAL '1 month',
  NOW() - INTERVAL '3 days';

INSERT INTO public.tasks (project_id, user_id, title, description, is_completed, due_date, priority, created_at, updated_at)
SELECT
  (SELECT id FROM public.projects WHERE title = 'Marketing Campaign Launch' AND user_id = (SELECT id FROM public.users WHERE email = 'jane.smith@example.com')),
  (SELECT id FROM public.users WHERE email = 'jane.smith@example.com'),
  'Email Newsletter Draft',
  'Write the draft for the product launch email newsletter.',
  false,
  NOW() + INTERVAL '2 weeks',
  'high',
  NOW() - INTERVAL '2 weeks',
  NOW() - INTERVAL '1 day';

INSERT INTO public.tasks (project_id, user_id, title, description, is_completed, due_date, priority, created_at, updated_at)
SELECT
  (SELECT id FROM public.projects WHERE title = 'Database Optimization' AND user_id = (SELECT id FROM public.users WHERE email = 'bob.johnson@example.com')),
  (SELECT id FROM public.users WHERE email = 'bob.johnson@example.com'),
  'Analyze Slow Queries',
  'Identify and analyze database queries that are performing poorly.',
  false,
  NOW() + INTERVAL '1 week',
  'high',
  NOW() - INTERVAL '3 weeks',
  NOW() - INTERVAL '2 days';

-- Insert sample time entries
INSERT INTO public.time_entries (user_id, project_id, task_id, description, start_time, end_time, duration_minutes, created_at, updated_at)
SELECT
  (SELECT id FROM public.users WHERE email = 'john.doe@example.com'),
  (SELECT id FROM public.projects WHERE title = 'Website Redesign' AND user_id = (SELECT id FROM public.users WHERE email = 'john.doe@example.com')),
  (SELECT id FROM public.tasks WHERE title = 'Design Homepage Mockups' AND user_id = (SELECT id FROM public.users WHERE email = 'john.doe@example.com')),
  'Initial design brainstorming',
  NOW() - INTERVAL '2 days' - INTERVAL '3 hours',
  NOW() - INTERVAL '2 days' - INTERVAL '1 hour',
  120,
  NOW() - INTERVAL '2 days' - INTERVAL '3 hours',
  NOW() - INTERVAL '2 days' - INTERVAL '1 hour';

INSERT INTO public.time_entries (user_id, project_id, task_id, description, start_time, end_time, duration_minutes, created_at, updated_at)
SELECT
  (SELECT id FROM public.users WHERE email = 'john.doe@example.com'),
  (SELECT id FROM public.projects WHERE title = 'Website Redesign' AND user_id = (SELECT id FROM public.users WHERE email = 'john.doe@example.com')),
  (SELECT id FROM public.tasks WHERE title = 'Design Homepage Mockups' AND user_id = (SELECT id FROM public.users WHERE email = 'john.doe@example.com')),
  'Working on wireframes',
  NOW() - INTERVAL '1 day' - INTERVAL '4 hours',
  NOW() - INTERVAL '1 day' - INTERVAL '1 hour',
  180,
  NOW() - INTERVAL '1 day' - INTERVAL '4 hours',
  NOW() - INTERVAL '1 day' - INTERVAL '1 hour';

INSERT INTO public.time_entries (user_id, project_id, task_id, description, start_time, end_time, duration_minutes, created_at, updated_at)
SELECT
  (SELECT id FROM public.users WHERE email = 'jane.smith@example.com'),
  (SELECT id FROM public.projects WHERE title = 'Marketing Campaign Launch' AND user_id = (SELECT id FROM public.users WHERE email = 'jane.smith@example.com')),
  (SELECT id FROM public.tasks WHERE title = 'Create Social Media Content' AND user_id = (SELECT id FROM public.users WHERE email = 'jane.smith@example.com')),
  'Researching social media trends',
  NOW() - INTERVAL '5 days' - INTERVAL '2 hours',
  NOW() - INTERVAL '5 days' - INTERVAL '1 hour',
  60,
  NOW() - INTERVAL '5 days' - INTERVAL '2 hours',
  NOW() - INTERVAL '5 days' - INTERVAL '1 hour';

INSERT INTO public.time_entries (user_id, project_id, task_id, description, start_time, end_time, duration_minutes, created_at, updated_at)
SELECT
  (SELECT id FROM public.users WHERE email = 'jane.smith@example.com'),
  (SELECT id FROM public.projects WHERE title = 'Marketing Campaign Launch' AND user_id = (SELECT id FROM public.users WHERE email = 'jane.smith@example.com')),
  (SELECT id FROM public.tasks WHERE title = 'Create Social Media Content' AND user_id = (SELECT id FROM public.users WHERE email = 'jane.smith@example.com')),
  'Drafting Instagram posts',
  NOW() - INTERVAL '4 days' - INTERVAL '3 hours',
  NOW() - INTERVAL '4 days' - INTERVAL '1 hour',
  120,
  NOW() - INTERVAL '4 days' - INTERVAL '3 hours',
  NOW() - INTERVAL '4 days' - INTERVAL '1 hour';

INSERT INTO public.time_entries (user_id, project_id, task_id, description, start_time, end_time, duration_minutes, created_at, updated_at)
SELECT
  (SELECT id FROM public.users WHERE email = 'bob.johnson@example.com'),
  (SELECT id FROM public.projects WHERE title = 'Database Optimization' AND user_id = (SELECT id FROM public.users WHERE email = 'bob.johnson@example.com')),
  (SELECT id FROM public.tasks WHERE title = 'Analyze Slow Queries' AND user_id = (SELECT id FROM public.users WHERE email = 'bob.johnson@example.com')),
  'Running performance tests',
  NOW() - INTERVAL '3 days' - INTERVAL '5 hours',
  NOW() - INTERVAL '3 days' - INTERVAL '2 hours',
  180,
  NOW() - INTERVAL '3 days' - INTERVAL '5 hours',
  NOW() - INTERVAL '3 days' - INTERVAL '2 hours';

INSERT INTO public.time_entries (user_id, project_id, task_id, description, start_time, end_time, duration_minutes, created_at, updated_at)
SELECT
  (SELECT id FROM public.users WHERE email = 'bob.johnson@example.com'),
  (SELECT id FROM public.projects WHERE title = 'Database Optimization' AND user_id = (SELECT id FROM public.users WHERE email = 'bob.johnson@example.com')),
  NULL, -- No specific task for this entry
  'General project overview',
  NOW() - INTERVAL '1 day' - INTERVAL '1 hour',
  NOW() - INTERVAL '1 day' - INTERVAL '30 minutes',
  30,
  NOW() - INTERVAL '1 day' - INTERVAL '1 hour',
  NOW() - INTERVAL '1 day' - INTERVAL '30 minutes';

INSERT INTO public.time_entries (user_id, project_id, task_id, description, start_time, end_time, duration_minutes, created_at, updated_at)
SELECT
  (SELECT id FROM public.users WHERE email = 'john.doe@example.com'),
  NULL, -- No specific project for this entry
  NULL, -- No specific task for this entry
  'Admin tasks and emails',
  NOW() - INTERVAL '6 hours',
  NOW() - INTERVAL '5 hours',
  60,
  NOW() - INTERVAL '6 hours',
  NOW() - INTERVAL '5 hours';