-- Users table (profile data linked to auth.users)
CREATE TABLE users (
  id UUID REFERENCES auth.users ON DELETE CASCADE,
  email TEXT NOT NULL,
  full_name TEXT NOT NULL,
  employee_id TEXT UNIQUE NOT NULL,
  role TEXT DEFAULT 'employee' CHECK (role IN ('admin', 'employee')),
  department TEXT,
  position TEXT,
  hourly_wage DECIMAL(10,2),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  PRIMARY KEY (id)
);

-- Time entries table (registro de ponto)
CREATE TABLE time_entries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  entry_type TEXT NOT NULL CHECK (entry_type IN ('clock_in', 'lunch_out', 'lunch_in', 'clock_out')),
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  location_lat DECIMAL(10, 8),
  location_lng DECIMAL(11, 8),
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Daily work summary table
CREATE TABLE daily_summaries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  work_date DATE NOT NULL,
  clock_in TIMESTAMP WITH TIME ZONE,
  lunch_out TIMESTAMP WITH TIME ZONE,
  lunch_in TIMESTAMP WITH TIME ZONE,
  clock_out TIMESTAMP WITH TIME ZONE,
  total_hours DECIMAL(4,2) DEFAULT 0,
  lunch_duration_minutes INTEGER DEFAULT 0,
  overtime_hours DECIMAL(4,2) DEFAULT 0,
  status TEXT DEFAULT 'incomplete' CHECK (status IN ('complete', 'incomplete', 'missing')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  UNIQUE(user_id, work_date)
);

-- Monthly summaries table
CREATE TABLE monthly_summaries (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE NOT NULL,
  year INTEGER NOT NULL,
  month INTEGER NOT NULL,
  total_work_hours DECIMAL(6,2) DEFAULT 0,
  total_overtime_hours DECIMAL(6,2) DEFAULT 0,
  days_worked INTEGER DEFAULT 0,
  days_missed INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  UNIQUE(user_id, year, month)
);

-- Create indexes for better performance
CREATE INDEX idx_users_employee_id ON users(employee_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_time_entries_user_id ON time_entries(user_id);
CREATE INDEX idx_time_entries_timestamp ON time_entries(timestamp);
CREATE INDEX idx_time_entries_type ON time_entries(entry_type);
CREATE INDEX idx_daily_summaries_user_date ON daily_summaries(user_id, work_date);
CREATE INDEX idx_daily_summaries_date ON daily_summaries(work_date);
CREATE INDEX idx_monthly_summaries_user_period ON monthly_summaries(user_id, year, month);