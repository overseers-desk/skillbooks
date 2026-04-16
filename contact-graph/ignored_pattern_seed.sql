-- Seed data for ignored_pattern
-- Covers automated senders, booking platforms, SaaS notifications,
-- bulk mail infrastructure, and similar noise.
-- Relevant to someone operating across tourism, tech (blockchain/token),
-- and events industries with accounts across multiple domains.

INSERT INTO ignored_pattern (pattern, pattern_type, reason) VALUES

-- -------------------------------------------------------------------------
-- Generic no-reply / automated sender addresses
-- -------------------------------------------------------------------------
('noreply',                       'domain', 'Generic no-reply subdomain used by many SaaS platforms'),
('no-reply',                      'domain', 'Variant no-reply subdomain'),
('donotreply',                    'domain', 'Variant do-not-reply subdomain'),
('bounce',                        'domain', 'Bounce-handling subdomain, not a human sender'),
('mailer-daemon',                 'domain', 'Mail transfer agent bounce address'),
('postmaster',                    'domain', 'Mail server administrative address'),
('noreply@github.com',            'address', 'GitHub automated notifications'),
('notifications@github.com',      'address', 'GitHub issue/PR notifications'),
('noreply@gitlab.com',            'address', 'GitLab automated notifications'),
('no-reply@accounts.google.com',  'address', 'Google account security alerts'),
('no-reply@google.com',           'address', 'Google automated mail'),
('noreply@notion.so',             'address', 'Notion workspace notifications'),
('noreply@slack.com',             'address', 'Slack notification emails'),
('no-reply@slack.com',            'address', 'Slack notification emails (variant)'),
('notifications@linear.app',      'address', 'Linear issue tracker notifications'),
('noreply@trello.com',            'address', 'Trello card activity notifications'),
('noreply@asana.com',             'address', 'Asana task notifications'),
('noreply@monday.com',            'address', 'Monday.com board notifications'),
('noreply@dropbox.com',           'address', 'Dropbox file share notifications'),
('noreply@zoom.us',               'address', 'Zoom meeting confirmations and recordings'),
('no-reply@zoom.us',              'address', 'Zoom automated mail (variant)'),
('noreply@calendly.com',          'address', 'Calendly booking confirmations'),
('noreply@cal.com',               'address', 'Cal.com booking notifications'),
('noreply@doodle.com',            'address', 'Doodle poll notifications'),

-- -------------------------------------------------------------------------
-- Booking and travel platforms (tourism context)
-- -------------------------------------------------------------------------
('getyourguide.com',              'domain', 'GetYourGuide booking platform — automated booking and review notifications'),
('rezdy.com',                     'domain', 'Rezdy booking system — automated confirmations and cancellations'),
('fareharbor.com',                'domain', 'FareHarbor booking platform automated mail'),
('bokun.io',                      'domain', 'Bokun tour booking platform notifications'),
('viator.com',                    'domain', 'Viator/TripAdvisor experience platform automated mail'),
('tripadvisor.com',               'domain', 'TripAdvisor review and listing notifications'),
('expedia.com',                   'domain', 'Expedia booking confirmation and promotional mail'),
('booking.com',                   'domain', 'Booking.com reservation and review notifications'),
('airbnb.com',                    'domain', 'Airbnb reservation notifications'),
('ihg.com',                       'domain', 'IHG hotel booking confirmations and loyalty notifications'),
('marriott.com',                  'domain', 'Marriott booking and loyalty notifications'),
('hilton.com',                    'domain', 'Hilton booking and loyalty notifications'),
('atdw.com.au',                   'domain', 'ATDW listing management automated notifications'),
('tourismaustralia.com',          'domain', 'Tourism Australia automated bulletins'),
('interlinetravel.com.au',        'domain', 'Interline Travel automated booking notifications'),

-- -------------------------------------------------------------------------
-- Events platforms
-- -------------------------------------------------------------------------
('eventbrite.com',                'domain', 'Eventbrite event registration and promotional notifications'),
('tickets.humanitix.com',         'domain', 'Humanitix ticketing platform notifications'),
('humanitix.com',                 'domain', 'Humanitix automated mail'),
('trybooking.com',                'domain', 'TryBooking ticketing platform notifications'),
('eventtemple.com',               'domain', 'Event Temple venue management notifications'),
('ivvy.com',                      'domain', 'iVvy venue and events management notifications'),

-- -------------------------------------------------------------------------
-- Financial, payroll, and HR SaaS
-- -------------------------------------------------------------------------
('xero.com',                      'domain', 'Xero accounting automated invoices and notifications'),
('myob.com',                      'domain', 'MYOB payroll and accounting automated mail'),
('deputy.com',                    'domain', 'Deputy rostering platform automated notifications'),
('tanda.co',                      'domain', 'Tanda workforce management notifications'),
('workato.com',                   'domain', 'Workato integration platform automated mail'),
('stripe.com',                    'domain', 'Stripe payment notifications'),
('paypal.com',                    'domain', 'PayPal transaction notifications'),
('invoices@paypal.com',           'address', 'PayPal invoice automated mail'),

-- -------------------------------------------------------------------------
-- Blockchain / token / Web3 platforms (tech context)
-- -------------------------------------------------------------------------
('noreply@etherscan.io',          'address', 'Etherscan blockchain explorer alerts'),
('info@etherscan.io',             'address', 'Etherscan promotional and system mail'),
('noreply@polygonscan.com',       'address', 'Polygonscan explorer alerts'),
('noreply@opensea.io',            'address', 'OpenSea NFT marketplace notifications'),
('noreply@rarible.com',           'address', 'Rarible marketplace notifications'),
('security@coinbase.com',         'address', 'Coinbase security automated alerts'),
('no-reply@coinbase.com',         'address', 'Coinbase automated notifications'),
('no-reply@binance.com',          'address', 'Binance exchange automated mail'),
('support@binance.com',           'address', 'Binance support queue automated responses'),
('noreply@metamask.io',           'address', 'MetaMask wallet notifications'),
('alchemy.com',                   'domain', 'Alchemy Web3 platform automated mail'),
('infura.io',                     'domain', 'Infura node provider automated notifications'),
('tenderly.co',                   'domain', 'Tenderly smart contract monitoring alerts'),

-- -------------------------------------------------------------------------
-- Marketing / CRM / mailing list infrastructure
-- -------------------------------------------------------------------------
('mailchimp.com',                 'domain', 'Mailchimp bulk sender domain'),
('mandrillapp.com',               'domain', 'Mandrill transactional mail relay (Mailchimp)'),
('sendgrid.net',                  'domain', 'SendGrid bulk/transactional mail relay'),
('sendgrid.com',                  'domain', 'SendGrid bulk/transactional mail relay (variant)'),
('mailgun.org',                   'domain', 'Mailgun transactional mail relay'),
('mailgun.net',                   'domain', 'Mailgun transactional mail relay (variant)'),
('amazonses.com',                 'domain', 'Amazon SES bulk/transactional mail relay'),
('bounces.amazon.com',            'domain', 'Amazon SES bounce handling'),
('klaviyo.com',                   'domain', 'Klaviyo marketing automation platform'),
('hubspot.com',                   'domain', 'HubSpot CRM and marketing automation mail'),
('salesforce.com',                'domain', 'Salesforce CRM automated notifications'),
('pardot.com',                    'domain', 'Pardot (Salesforce) marketing automation'),
('constantcontact.com',           'domain', 'Constant Contact bulk mail platform'),
('campaignmonitor.com',           'domain', 'Campaign Monitor bulk mail platform'),
('activecampaign.com',            'domain', 'ActiveCampaign marketing automation'),
('intercom.io',                   'domain', 'Intercom customer messaging platform automated mail'),
('freshdesk.com',                 'domain', 'Freshdesk support ticket automated responses'),
('zendesk.com',                   'domain', 'Zendesk support ticket automated responses'),

-- -------------------------------------------------------------------------
-- Social networks and professional platforms (automated notification mail)
-- -------------------------------------------------------------------------
('linkedin.com',                  'domain', 'LinkedIn connection and notification mail — profile data comes from the LinkedIn skill, not email'),
('facebook.com',                  'domain', 'Facebook automated notification mail'),
('facebookmail.com',              'domain', 'Facebook bulk notification relay domain'),
('instagram.com',                 'domain', 'Instagram automated notification mail'),
('twitter.com',                   'domain', 'Twitter/X automated notification mail'),
('x.com',                         'domain', 'X (Twitter) automated notification mail'),

-- -------------------------------------------------------------------------
-- Government and regulatory automated mail (Australia)
-- -------------------------------------------------------------------------
('ato.gov.au',                    'domain', 'Australian Taxation Office automated notices'),
('abr.gov.au',                    'domain', 'ABN registration automated mail'),
('business.gov.au',               'domain', 'business.gov.au automated notifications'),
('qld.gov.au',                    'domain', 'Queensland Government automated administrative mail'),
('nsw.gov.au',                    'domain', 'NSW Government automated administrative mail'),
('vic.gov.au',                    'domain', 'Victoria Government automated administrative mail'),

-- -------------------------------------------------------------------------
-- Veterinary and scheduling software (observed in corpus)
-- -------------------------------------------------------------------------
('ezyvet.com',                    'domain', 'EzyVet veterinary clinic software automated notifications'),
('acuityscheduling.com',          'domain', 'Acuity Scheduling booking confirmation and reminder mail'),

-- -------------------------------------------------------------------------
-- Google system addresses (observed in corpus)
-- -------------------------------------------------------------------------
('calendar-notification@google.com',     'address', 'Google Calendar automated event notifications'),
('CloudPlatform-noreply@google.com',      'address', 'Google Cloud Platform automated alerts'),
('drive-shares-noreply@google.com',       'address', 'Google Drive share notifications'),
('bard-noreply@google.com',               'address', 'Google Bard/Gemini automated mail'),

-- -------------------------------------------------------------------------
-- Regex patterns for dynamic/wildcard addresses (observed in corpus)
-- -------------------------------------------------------------------------
('\+acct_[0-9A-Za-z]+@stripe\.com',       'regex', 'Stripe per-account dynamic address — e.g. failed-payments+acct_1AbCd@stripe.com'),
('^alerts@',                              'regex', 'Generic automated alerts address prefix'),
('^digest@',                              'regex', 'Generic digest/newsletter address prefix'),
('^newsletter@',                          'regex', 'Generic newsletter address prefix'),
('^updates@',                             'regex', 'Generic updates address prefix'),
('^noreply\+',                            'regex', 'Noreply address with dynamic suffix — bulk sender tracking tag');
