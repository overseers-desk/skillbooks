-- Seed data for ignored_pattern
-- Derived from manual study of the email corpus across 2001–2026.
--
-- Two tiers:
--
--   Tier 1 — local-part regex patterns, domain-agnostic.
--             Applied against the full From address; catches automated mail
--             regardless of which domain sends it.
--
--   Tier 2 — pure relay/infrastructure domains.
--             Domains with no human senders. Company domains (stripe.com,
--             github.com, etc.) are excluded — they have human staff, and
--             their automated addresses are caught by Tier 1.
--
-- Note: PostgreSQL ~ is case-sensitive by default. Patterns use (?i) where
-- case variance was observed in the corpus.

INSERT INTO ignored_pattern (pattern, pattern_type, reason) VALUES

-- =========================================================================
-- Tier 1: local-part regex patterns
-- =========================================================================

-- -------------------------------------------------------------------------
-- No-reply family
-- -------------------------------------------------------------------------
-- Anchored prefix forms
('^noreply@',                      'regex', 'No-reply prefix — automated outbound'),
('^no-reply@',                     'regex', 'No-reply prefix, hyphenated variant'),
('^no_reply@',                     'regex', 'No-reply prefix, underscore variant (Apple, Zavvi, etc.)'),
('^donotreply@',                   'regex', 'Do-not-reply, run-together form'),
('^do-not-reply@',                 'regex', 'Do-not-reply, hyphenated form'),
('^do_not_reply@',                 'regex', 'Do-not-reply, underscore form (Harvey Norman, iTunes, etc.)'),
('^donot\.reply@',                 'regex', 'Do-not-reply, dot-separator form (TAFE NSW, etc.)'),
-- Suffix/infix forms — noreply or no-reply as a component, not prefix
-- e.g. firebase-noreply@, analytics-noreply@, notifications-noreply@, updates-noreply@
('(noreply|no[-_.]reply)@',        'regex', 'No-reply as suffix or infix of local part — catches firebase-noreply@, analytics-noreply@, notifications-noreply@bitbucket.org, etc.'),

-- -------------------------------------------------------------------------
-- MTA infrastructure
-- -------------------------------------------------------------------------
('(?i)^mailer-daemon@',            'regex', 'MTA bounce handler — case-insensitive; corpus has both mailer-daemon@ and MAILER-DAEMON@'),
('(?i)^postmaster@',               'regex', 'Mail server admin — automated in practice'),
('^bounce[s]?@',                   'regex', 'Bounce-handling address prefix'),
('-bounces@',                      'regex', 'Mailman/Listserv list bounce envelope sender — e.g. gnome-cn-list-bounces@gnome.org'),

-- -------------------------------------------------------------------------
-- Auto-reply / out-of-office
-- -------------------------------------------------------------------------
('^autoreply@',                    'regex', 'Auto-reply sender'),
('^auto-reply@',                   'regex', 'Auto-reply sender, hyphenated'),

-- -------------------------------------------------------------------------
-- Notification infrastructure
-- -------------------------------------------------------------------------
('^notification[s]?@',             'regex', 'Notification dispatch address'),

-- -------------------------------------------------------------------------
-- Bulk-sender tracking tags (dynamic subaddresses)
-- -------------------------------------------------------------------------
-- Original: \+[a-z0-9]{8,}@ — widened to include uppercase and underscore
-- for Stripe acct_ tags: receipts+acct_1DhKArHebh5Mf9AG@stripe.com
('\+[a-zA-Z0-9_]{6,}@',           'regex', 'Address with long tracking suffix — bulk sender per-recipient tag (Stripe acct_, SendGrid, etc.)'),

-- -------------------------------------------------------------------------
-- Mailing list infrastructure
-- -------------------------------------------------------------------------
('^majordomo@',                    'regex', 'Majordomo mailing list manager daemon'),
('^mailman-owner@',                'regex', 'Mailman automated list membership reminders'),
('^listmaster@',                   'regex', 'Mailing list admin robot address'),
('(?i)^listserv@',                 'regex', 'LISTSERV bulk-mail manager — case-insensitive; seen as LISTSERV@ABCNEWSLETTERS.NET.AU'),
('-request@',                      'regex', 'Mailman/listserv subscription management address — e.g. gimp-print-devel-request@lists.sf.net'),

-- -------------------------------------------------------------------------
-- Bug trackers and CI
-- -------------------------------------------------------------------------
('^bugzilla-daemon@',              'regex', 'Bugzilla automated notification daemon — appears every year 2004–2016 across mozilla.org, gentoo.org, gnome.org'),
('^trac@',                         'regex', 'Trac issue-tracker notification robot'),
('^nagios@',                       'regex', 'Nagios/monitoring daemon — never a human sender'),
('^root@',                         'regex', 'Server system user — cron, Installatron, Let''s Encrypt renewal notices'),

-- -------------------------------------------------------------------------
-- Other automation patterns observed in corpus
-- -------------------------------------------------------------------------
('^posting-system@',               'regex', 'Google Groups newsgroup relay — machine-generated copies of Usenet posts'),
('^virusalert@',                   'regex', 'MTA AV-filter notification address (amavisd/ClamAV)'),
('^website@',                      'regex', 'CMS-generated org announcement address — not a named person'),

-- =========================================================================
-- Tier 2: pure relay/infrastructure domains (no human senders)
-- =========================================================================

-- -------------------------------------------------------------------------
-- Generic relay infrastructure
-- -------------------------------------------------------------------------
('sendgrid.net',                   'domain', 'SendGrid relay infrastructure'),
('amazonses.com',                  'domain', 'Amazon SES relay infrastructure'),
('mailgun.org',                    'domain', 'Mailgun relay infrastructure'),
('mailgun.net',                    'domain', 'Mailgun relay infrastructure (variant)'),
('mandrillapp.com',                'domain', 'Mailchimp Mandrill transactional relay'),
('bounces.amazon.com',             'domain', 'Amazon SES bounce handling'),

-- -------------------------------------------------------------------------
-- AWS subdomains (separate from amazonses.com)
-- -------------------------------------------------------------------------
('costalerts.amazonaws.com',       'domain', 'AWS cost-alert subdomain — billing threshold notifications only'),
('sns.amazonaws.com',              'domain', 'AWS SNS notification relay'),

-- -------------------------------------------------------------------------
-- Software/dev tooling
-- -------------------------------------------------------------------------
('atlassian.net',                  'domain', 'Jira/Confluence notification relay — Reply-To carries the human, @atlassian.net is system-only'),
('travis-ci.com',                  'domain', 'Travis CI build notifications — no human sender'),
('discoursemail.com',              'domain', 'Discourse forum digest/notification relay'),
('dtdg.co',                        'domain', 'Datadog alert and dashboard report sending domain'),

-- -------------------------------------------------------------------------
-- Financial/payment subdomains
-- Only the relay subdomain is blocked, not the parent company domain
-- -------------------------------------------------------------------------
('intl.paypal.com',                'domain', 'PayPal transactional relay subdomain — human PayPal staff use @paypal.com'),
('mail.alipay.com',                'domain', 'Alipay transactional relay subdomain'),

-- -------------------------------------------------------------------------
-- Social/communication relay subdomains
-- -------------------------------------------------------------------------
('facebookmail.com',               'domain', 'Facebook bulk notification relay — all observed senders are automated'),
('em.linkedin.com',                'domain', 'LinkedIn ESP relay subdomain — human LinkedIn staff use @linkedin.com'),
('shadow.outlook.com',             'domain', 'Microsoft opaque relay domain — local parts are 64-char hex hashes; real sender in display name'),

-- -------------------------------------------------------------------------
-- Australian services
-- -------------------------------------------------------------------------
('notifications.auspost.com.au',   'domain', 'Australia Post parcel notification relay subdomain'),
('post.xero.com',                  'domain', 'Xero invoice-relay subdomain — human Xero contacts use @xero.com'),

-- -------------------------------------------------------------------------
-- Specialised relay domains observed in corpus
-- -------------------------------------------------------------------------
('unknown.email',                  'domain', 'Pseudo-domain used by SMS-to-email backup tools (SMS Backup+) — addresses like +61412345678@unknown.email are SMS contacts, not email'),
('print.epsonconnect.com',         'domain', 'Epson cloud print relay — local parts are hardware device IDs, no human sender possible'),
('moneybookers.com',               'domain', 'Historical Skrill payment service automated mail'),
('nearlyfreespeech.net',           'domain', 'Hosting infrastructure alerts only — notify@ and domains@ are both automated monitors'),
('caixinmedia.com',                'domain', 'Caixin Online bulk newsletter ESP — rotating numbered subdomain hosts, no human senders'),
('followistic.com',                'domain', 'RSS-to-email newsletter relay'),

-- =========================================================================
-- Specific addresses (domain too broad to filter entirely)
-- =========================================================================
('ask@baidu.com',                  'address', 'Baidu advertising system automated billing reports — not a contact'),
('certmaster@startcom.org',        'address', 'StartCom CA OTP and certificate issuance robot'),
('int-renew@thawte.com',           'address', 'Thawte SSL renewal blast — Verisign bulk commercial'),
('ibanking.alert@dbs.com',         'address', 'DBS bank transaction alert robot'),
('NetBankNotification@cba.com.au', 'address', 'CBA bank automated transaction alert — no Reply-To'),
('expiry@letsencrypt.org',         'address', "Let's Encrypt certificate expiry bot"),

-- =========================================================================
-- Subject patterns (sender address varies, subject is the stable signal)
-- =========================================================================
('^AUTO RENEW NOTICE',             'subject', 'Domain registrar auto-renewal notices — sender varies across registrars'),
('certificate.*expir',             'subject', 'SSL/TLS certificate expiry alerts from CAs — sender varies across RapidSSL, CAcert, StartSSL, etc.');
