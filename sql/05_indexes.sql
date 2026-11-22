SET search_path TO linkedin;

-- R02, R17, R25: member position history and window ordering
CREATE INDEX idx_positions_member_start
ON positions (member_id, start_date);

-- R03, R04, R05: connection lookups from either member
CREATE INDEX idx_connections_member_b
ON connections (member_b, connected_at DESC)
INCLUDE (member_a);

-- R10, W02, W03: pending invitation lookup
CREATE INDEX idx_invitations_recipient_status
ON invitations (recipient_id, status, invitation_id)
INCLUDE (sender_id, sent_at, note);

-- R11: profile views for a particular member and date
CREATE INDEX idx_profile_views_viewed_date
ON profile_views (viewed_id, viewed_at)
INCLUDE (viewer_id);

-- R13: find members who have never viewed a profile
CREATE INDEX idx_profile_views_viewer
ON profile_views (viewer_id)
WHERE viewer_id IS NOT NULL;

-- R19: applications belonging to jobs, filtered by application date
CREATE INDEX idx_applications_job_date
ON applications (job_id, applied_at);

-- R20, R22: date filtering and newest-first application pagination
CREATE INDEX idx_applications_applied_at
ON applications (applied_at DESC)
INCLUDE (application_id, job_id, member_id, status);

-- R21, R18: skill ranking and endorsement ordering
CREATE INDEX idx_member_skills_skill_endorsements
ON member_skills (skill_id, endorsements DESC, member_id);

-- R23: case-insensitive email lookup
CREATE INDEX idx_members_lower_email
ON members (lower(email));

-- R09: Speed up member application history lookups.
CREATE INDEX IF NOT EXISTS idx_applications_member_applied_at
ON linkedin.applications (member_id, applied_at DESC)
INCLUDE (application_id, job_id, status);

