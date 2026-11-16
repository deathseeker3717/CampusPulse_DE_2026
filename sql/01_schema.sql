
-- LinkedIn Professional Network Database
-- Phase 1: Schema creation
-- PostgreSQL 15+

CREATE SCHEMA IF NOT EXISTS linkedin;
SET search_path TO linkedin;

-- 1. Cities
CREATE TABLE cities (
    city_id INTEGER PRIMARY KEY,
    city_name TEXT NOT NULL,
    state TEXT NOT NULL
);

-- 2. Companies
CREATE TABLE companies (
    company_id INTEGER PRIMARY KEY,
    company_name TEXT NOT NULL,
    industry TEXT NOT NULL CHECK (
        industry IN (
            'Banking', 'Consulting', 'E-commerce', 'EdTech',
            'Fintech', 'Healthcare', 'IT Services',
            'Manufacturing', 'Software', 'Telecom'
        )
    ),
    company_size TEXT NOT NULL CHECK (
        company_size IN (
            '1-10', '11-50', '51-200', '201-1000',
            '1001-5000', '5001-10000', '10001+'
        )
    ),
    hq_city_id INTEGER NOT NULL,
    founded_year INTEGER NOT NULL,
    website TEXT,

    CONSTRAINT fk_companies_city
        FOREIGN KEY (hq_city_id)
        REFERENCES cities(city_id)
);

-- 3. Members
CREATE TABLE members (
    member_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    headline TEXT,
    email TEXT NOT NULL,
    city_id INTEGER,
    industry TEXT NOT NULL CHECK (
        industry IN (
            'Banking', 'Consulting', 'E-commerce', 'EdTech',
            'Fintech', 'Healthcare', 'IT Services',
            'Manufacturing', 'Software', 'Telecom'
        )
    ),
    is_premium BOOLEAN NOT NULL,
    open_to_work BOOLEAN NOT NULL,
    created_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_members_city
        FOREIGN KEY (city_id)
        REFERENCES cities(city_id)
);

-- 4. Skills
CREATE TABLE skills (
    skill_id INTEGER PRIMARY KEY,
    skill_name TEXT NOT NULL
);

-- 5. Positions
CREATE TABLE positions (
    position_id INTEGER PRIMARY KEY,
    member_id INTEGER NOT NULL,
    company_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    employment_type TEXT NOT NULL CHECK (
        employment_type IN ('CONTRACT', 'FULL_TIME', 'INTERNSHIP')
    ),
    start_date DATE NOT NULL,
    end_date DATE,

    CONSTRAINT fk_positions_member
        FOREIGN KEY (member_id)
        REFERENCES members(member_id),

    CONSTRAINT fk_positions_company
        FOREIGN KEY (company_id)
        REFERENCES companies(company_id)
);

-- 6. Member Skills
CREATE TABLE member_skills (
    member_id INTEGER NOT NULL,
    skill_id INTEGER NOT NULL,
    endorsements INTEGER NOT NULL CHECK (endorsements >= 0),

    PRIMARY KEY (member_id, skill_id),

    CONSTRAINT fk_member_skills_member
        FOREIGN KEY (member_id)
        REFERENCES members(member_id),

    CONSTRAINT fk_member_skills_skill
        FOREIGN KEY (skill_id)
        REFERENCES skills(skill_id)
);

-- 7. Connections
CREATE TABLE connections (
    member_a INTEGER NOT NULL,
    member_b INTEGER NOT NULL,
    connected_at TIMESTAMPTZ NOT NULL,

    PRIMARY KEY (member_a, member_b),

    CONSTRAINT fk_connections_member_a
        FOREIGN KEY (member_a)
        REFERENCES members(member_id),

    CONSTRAINT fk_connections_member_b
        FOREIGN KEY (member_b)
        REFERENCES members(member_id)
);

-- 8. Invitations
CREATE TABLE invitations (
    invitation_id INTEGER PRIMARY KEY,
    sender_id INTEGER NOT NULL,
    recipient_id INTEGER NOT NULL,
    note TEXT,
    sent_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL CHECK (
        status IN ('ACCEPTED', 'IGNORED', 'PENDING', 'WITHDRAWN')
    ),
    responded_at TIMESTAMPTZ,

    CONSTRAINT fk_invitations_sender
        FOREIGN KEY (sender_id)
        REFERENCES members(member_id),

    CONSTRAINT fk_invitations_recipient
        FOREIGN KEY (recipient_id)
        REFERENCES members(member_id)
);

-- 9. Jobs
CREATE TABLE jobs (
    job_id INTEGER PRIMARY KEY,
    company_id INTEGER NOT NULL,
    title TEXT NOT NULL,
    city_id INTEGER,
    workplace_type TEXT NOT NULL CHECK (
        workplace_type IN ('HYBRID', 'ONSITE', 'REMOTE')
    ),
    employment_type TEXT NOT NULL CHECK (
        employment_type IN ('CONTRACT', 'FULL_TIME', 'INTERNSHIP')
    ),
    min_experience INTEGER NOT NULL CHECK (min_experience >= 0),
    min_salary_lpa NUMERIC(10, 2) CHECK (min_salary_lpa >= 0),
    max_salary_lpa NUMERIC(10, 2) CHECK (max_salary_lpa >= 0),
    posted_at TIMESTAMPTZ NOT NULL,
    closes_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('CLOSED', 'OPEN')),

    CONSTRAINT fk_jobs_company
        FOREIGN KEY (company_id)
        REFERENCES companies(company_id),

    CONSTRAINT fk_jobs_city
        FOREIGN KEY (city_id)
        REFERENCES cities(city_id),

    CONSTRAINT chk_jobs_salary_range
        CHECK (
            min_salary_lpa IS NULL
            OR max_salary_lpa IS NULL
            OR min_salary_lpa <= max_salary_lpa
        )
);

-- 10. Job Skills
CREATE TABLE job_skills (
    job_id INTEGER NOT NULL,
    skill_id INTEGER NOT NULL,

    PRIMARY KEY (job_id, skill_id),

    CONSTRAINT fk_job_skills_job
        FOREIGN KEY (job_id)
        REFERENCES jobs(job_id),

    CONSTRAINT fk_job_skills_skill
        FOREIGN KEY (skill_id)
        REFERENCES skills(skill_id)
);

-- 11. Applications
CREATE TABLE applications (
    application_id INTEGER PRIMARY KEY,
    job_id INTEGER NOT NULL,
    member_id INTEGER NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL,
    easy_apply BOOLEAN NOT NULL,
    status TEXT NOT NULL CHECK (
        status IN (
            'APPLIED', 'HIRED', 'INTERVIEW', 'OFFER',
            'REJECTED', 'SHORTLISTED', 'VIEWED', 'WITHDRAWN'
        )
    ),
    status_updated_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_applications_job
        FOREIGN KEY (job_id)
        REFERENCES jobs(job_id),

    CONSTRAINT fk_applications_member
        FOREIGN KEY (member_id)
        REFERENCES members(member_id)
);

-- 12. Profile Views
CREATE TABLE profile_views (
    view_id INTEGER PRIMARY KEY,
    viewer_id INTEGER,
    viewed_id INTEGER NOT NULL,
    viewed_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT fk_profile_views_viewer
        FOREIGN KEY (viewer_id)
        REFERENCES members(member_id),

    CONSTRAINT fk_profile_views_viewed
        FOREIGN KEY (viewed_id)
        REFERENCES members(member_id)
);
