-- Seed data for ignored_pattern
--
-- Two tiers only:
--
--   Tier 1 — local-part regex patterns, domain-agnostic.
--             A dozen rules that catch automated mail regardless of which
--             company sends it. noreply@stripe.com and noreply@notion.so
--             are both caught; stripe.com and notion.so remain unblocked
--             so human staff at those companies pass through.
--
--   Tier 2 — pure relay infrastructure domains.
--             Domains where no human sender exists — only relay services.
--             Company domains (stripe.com, github.com, xero.com) are
--             deliberately excluded: they have human staff and only their
--             automated local-parts are caught by tier 1.

INSERT INTO ignored_pattern (pattern, pattern_type, reason) VALUES

-- -------------------------------------------------------------------------
-- Tier 1: local-part patterns (regex, domain-agnostic)
-- -------------------------------------------------------------------------
('^noreply@',           'regex', 'No-reply sender — automated outbound, no human reads replies'),
('^no-reply@',          'regex', 'No-reply sender (hyphenated variant)'),
('^donotreply@',        'regex', 'Do-not-reply sender'),
('^do-not-reply@',      'regex', 'Do-not-reply sender (hyphenated variant)'),
('^mailer-daemon@',     'regex', 'MTA bounce handler — never a human'),
('^postmaster@',        'regex', 'Mail server administrative address — automated in practice'),
('^bounce[s]?@',        'regex', 'Bounce-handling address'),
('^autoreply@',         'regex', 'Auto-reply sender'),
('^auto-reply@',        'regex', 'Auto-reply sender (hyphenated variant)'),
('^notification[s]?@',  'regex', 'Notification sender — automated dispatch address'),
('\+[a-z0-9]{8,}@',     'regex', 'Address with long tracking suffix — bulk sender using per-recipient tags (e.g. Stripe +acct_*, SendGrid click-tracking addresses)');

-- -------------------------------------------------------------------------
-- Tier 2: pure relay infrastructure domains
-- Domains with no human senders — relay infrastructure only.
-- -------------------------------------------------------------------------
INSERT INTO ignored_pattern (pattern, pattern_type, reason) VALUES
('sendgrid.net',        'domain', 'SendGrid relay infrastructure — all mail is relayed bulk/transactional, no human senders at this domain'),
('amazonses.com',       'domain', 'Amazon SES relay infrastructure — no human senders'),
('mailgun.org',         'domain', 'Mailgun relay infrastructure — no human senders'),
('mailgun.net',         'domain', 'Mailgun relay infrastructure (variant domain)'),
('mandrillapp.com',     'domain', 'Mailchimp Mandrill transactional relay — no human senders'),
('bounces.amazon.com',  'domain', 'Amazon SES bounce-handling subdomain');
