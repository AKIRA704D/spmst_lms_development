-- ============================================================================
-- SPAMAST LMSA  -  PROPOSED performance indexes   (NOT applied automatically)
-- Review first. All statements are ADDITIVE: no table/column/FK is changed and
-- no rows are touched. Each index only costs a little disk and slightly slower
-- INSERT/UPDATE on that table. Safe to run on MySQL 5.7+/8.
--
-- HOW TO USE
--  1. Take a backup (or at least run on a copy first).
--  2. Run the CHECK query below; skip any index that already exists.
--  3. Run the statements you want, one at a time, outside peak hours.
--  4. Compare EXPLAIN for the slow queries before/after.
--  5. Rollback = the DROP INDEX lines at the bottom.
-- ============================================================================

-- CHECK: which of these already exist?
SELECT table_name, index_name, GROUP_CONCAT(column_name ORDER BY seq_in_index) AS cols
FROM information_schema.statistics
WHERE table_schema = DATABASE()
  AND table_name IN ('library_attendance','audit_logs','transactions','item_copies','library_resources','penalties')
GROUP BY table_name, index_name;

-- 1) Attendance Monitor / dashboards filter "today" by time_in (every 30 s on the monitor page).
--    Today only idx_user_id exists, so these scan the whole attendance table.
CREATE INDEX idx_attendance_time_in      ON library_attendance (time_in);
CREATE INDEX idx_attendance_user_timein  ON library_attendance (user_id, time_in);

-- 2) System Logs page sorts/filters by newest first; audit_logs only has idx_user_id.
CREATE INDEX idx_audit_created_at        ON audit_logs (created_at);
CREATE INDEX idx_audit_action_created    ON audit_logs (action_type, created_at);

-- 3) Circulation: open loans (return_date IS NULL), overdue scans and per-patron history.
CREATE INDEX idx_txn_return_date         ON transactions (return_date);
CREATE INDEX idx_txn_status_due          ON transactions (status, due_date);
CREATE INDEX idx_txn_user_status         ON transactions (user_id, status);
CREATE INDEX idx_txn_created_at          ON transactions (created_at);

-- 4) Catalog: availability checks per resource, and lookup by ISBN / title prefix.
CREATE INDEX idx_copies_resource_avail   ON item_copies (resource_id, is_available);
CREATE INDEX idx_resources_isbn          ON library_resources (isbn);
CREATE INDEX idx_resources_title         ON library_resources (title(100));
-- NOTE: LIKE '%text%' searches cannot use any B-tree index. If catalog search is still slow,
-- the next step is a FULLTEXT index + MATCH ... AGAINST (needs a code change; not included).

-- 5) Penalties list: filtered by status, newest first.
CREATE INDEX idx_penalty_status_created  ON penalties (fine_status, created_at);

-- ============================================================================
-- ROLLBACK
-- ============================================================================
-- DROP INDEX idx_attendance_time_in     ON library_attendance;
-- DROP INDEX idx_attendance_user_timein ON library_attendance;
-- DROP INDEX idx_audit_created_at       ON audit_logs;
-- DROP INDEX idx_audit_action_created   ON audit_logs;
-- DROP INDEX idx_txn_return_date        ON transactions;
-- DROP INDEX idx_txn_status_due         ON transactions;
-- DROP INDEX idx_txn_user_status        ON transactions;
-- DROP INDEX idx_txn_created_at         ON transactions;
-- DROP INDEX idx_copies_resource_avail  ON item_copies;
-- DROP INDEX idx_resources_isbn         ON library_resources;
-- DROP INDEX idx_resources_title        ON library_resources;
-- DROP INDEX idx_penalty_status_created ON penalties;
