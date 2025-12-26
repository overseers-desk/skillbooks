# Travel Admin Folder Management Standard Operating Procedure

## Purpose Statement

This Standard Operating Procedure establishes the methodology for managing the Travel Admin folder structure and file organization. The SOP ensures systematic organization through proper folder structure verification, intelligent file naming conventions, and email synchronization to guarantee that all booking confirmations are saved and properly named.

The procedure transforms chaotic travel documentation into a well-organized system where files follow consistent naming patterns, emails are synchronized with folder contents, and reimbursement documents are properly categorized—creating a reliable foundation for subsequent journey evaluation and itinerary generation (see Travel Itinerary Management SOP).

## Scope

This SOP applies to file organization and email synchronization within the "Travel Admin" folder (see `sop-travel-folder-access.md` for access methods). The procedure focuses exclusively on:

- Verifying file organization and naming compliance
- Extracting booking information and applying correct naming conventions
- Synchronizing email confirmations with folder contents
- Organizing reimbursement documents with proper categorization
- Managing promotional email cleanup for completed journeys

**Important Boundaries:**

- This SOP is **NOT** for journey completeness evaluation. It does not assess travel gaps, evaluate transport connections, or verify accommodation continuity.
- This SOP is **NOT** for itinerary generation. It does not create travel timelines or generate itinerary documents.
- For journey evaluation and itinerary creation, see the Travel Itinerary Management SOP (`travel-itinerary-management.md`).

The execution can be performed on:

- **Single journey processing** (typical use case): Complete folder management for one journey
- **Bulk file operations**: Renaming and organizing files across multiple journeys according to naming conventions

## Journey Folders and RUN Execution

### Journey Folders

A journey folder contains all documentation for a specific trip, including transport bookings, accommodation reservations, event tickets, and reimbursement documents. Journey folders are organized with a date-prefixed naming structure (e.g., "2025-11-15 Lisbon - Weiwu, Liansu, A-Z") and contain standardized subfolders: Fares, Accommodations, Passes, and optionally Reimbursement folders.

Files may originate from various sources: email confirmations, WhatsApp messages, photographs of physical documents (boarding passes, receipts), or forwarded from other travelers' mailboxes. The source doesn't affect how files are processed—all files in the folder are organised and named according to the same conventions regardless of origin.

**Default Location**: See `sop-travel-folder-access.md` for how to access travel folders. That SOP defines the access methods (MCP preferred, filesystem mount fallback) and is the single source of truth for folder location. When processing a journey, if only the folder name is provided, the system assumes it is located within the Travel Admin parent directory.

### RUN: Folder Management Execution

A **RUN** is a complete folder management pass through a journey folder, executing all procedures in sequence to ensure files are properly organized, named correctly, and synchronized with email confirmations. This SOP covers the folder management aspects only—for journey completeness evaluation and itinerary generation, see the Travel Itinerary Management SOP (`travel-itinerary-management.md`).

**RUN Workflow:**

0. **Access Data: Examine Online Travel Folder** (Prerequisite):
   - Follow `sop-travel-folder-access.md` for instructions on how to access the travel data.
   - This ensures the online data source exists.

1. **File Organization and Naming** (Procedure 1): Verify folder structure, ensure naming convention compliance, extract information from booking documents, apply correct naming conventions, move orphaned files, and apply reimbursement file naming where needed.
   - **Crucial**: The `Fares`, `Accommodations`, and `Passes` folders MUST have a flat structure. No subfolders are permitted.

2. **Email Checking and File Saving** (Procedure 2): Search inbox for booking confirmations, identify missing files, save invoices to reimbursement folders, and flag promotional emails for deletion

**Re-runnability by Design:**

RUN is designed to be executed multiple times (typically 1-10 times) as new bookings arrive or information changes. Each procedure is idempotent, meaning:

- Files already saved are not re-saved (checked before flagging for action)
- Files already correctly named are not renamed
- Email searches skip already-processed confirmations
- Subsequent RUN executions build on previous work without duplication

This re-runnable design allows the journey folder to evolve naturally as bookings are made, cancelled, or modified, with each RUN incorporating new information while preserving previous work.

**Subsequent Processing:**

After completing folder management RUN, you may optionally proceed to journey evaluation and itinerary generation using the Travel Itinerary Management SOP (`travel-itinerary-management.md`). That SOP handles:

- Mental journey simulation and completeness evaluation
- Itinerary document creation/update with gap analysis
- Booking recommendations for identified gaps

The separation allows automated systems to run folder management independently, while itinerary management may require user confirmation and can be invoked separately.

## Prerequisites

Before executing procedures (individually or as a complete RUN), ensure:

1. **Access to Travel Admin folder ("0. Travel Admin"):**
   - Follow `sop-travel-folder-access.md` to access travel folders (MCP preferred, filesystem mount fallback)
   - Do not use `find(1)` command in any folder other than `0. Travel Admin` (10k+ files exist in cloud storage; broad searches take excessive time)
   - Do not use `find(1)` to locate `0. Travel Admin` itself—the folder location is defined in the access SOP and is guaranteed to exist
   - If access fails via both methods, the whole process should fail
   - Ability to read and modify files within journey folders
   - Permission to create or update Itinerary.md documents

2. **Knowledge Requirements:**
   - Familiarity with the Travel Handbook (naming conventions, folder structure, email account rules)
   - Understanding of the Travel Preferences document
   - Basic understanding of travel terminology (PNR, airport codes, layovers)

3. **Tools Available:**
   - PDF text extraction capability (pdftotext or equivalent)
   - Access to internet search for verifying transport schedules, airport information
   - Word processing software for creating/updating Itinerary.docx

4. **Context Understanding:**
   - Awareness of traveler composition (children, elderly, special needs) when evaluating transport options
   - Basic geographic knowledge for airport proximity assessment
   - Understanding of regional travel patterns (e.g., Balkan countries, Middle East connections)

## File Naming Conventions

These naming conventions apply across multiple procedures and must be followed consistently.

### Fare Files (in Fares folder)

Format: `YYYY-MM-DD [Airline/Transport] Origin-Destination FlightNumber BookingRef [Optional FF Points] [Optional Passengers].pdf`

For cancelled bookings: `(Cancelled) YYYY-MM-DD [Airline/Transport] Origin-Destination FlightNumber BookingRef [Optional FF Points] [Optional Passengers].pdf`

**Required components:**

- **Date**: Travel/use date (NOT booking/purchase date) in YYYY-MM-DD format
- **Transport provider**: In square brackets, e.g., `[Ryanair]`, `[CP]`, `[Singapore Airlines]`
- **Route**: Origin-Destination using hyphens (e.g., `Seville-Porto`, `Vila Nova de Gaia-Devesas-Lisbon Santa Apolonia`)
- **Flight/Train number**: Flight number (e.g., `FR1073`, `SQ265`) or train number (e.g., `IC130`, `AVE2991`). For buses, car rentals, or transport without fixed numbers, omit this component.
- **Booking reference**: PNR code, ticket ID, or confirmation number

**Optional components:**

- **Cancellation prefix**: `(Cancelled) ` at the start if the booking was cancelled (note the space after the closing parenthesis)
- **Frequent Flyer points**: In parentheses, e.g., `(Qantas +3500)` for claimed points, `(Qantas!)` for unclaimed but eligible
- **Passengers**: Comma-separated, no spaces, e.g., `Liansu,Weiwu,Alice,Zoe` or abbreviated `A-Z` when appropriate

**Multi-segment and Round-trip Bookings:**

When a single booking confirmation contains multiple flight segments (connecting flights or round-trip journeys), keep as a single file using these conventions:

- **Connecting flights (one-way)**: Use first flight number only: `2025-06-15 [Qantas] Singapore-Melbourne-Sydney QF52 ABCDEF.pdf` (connecting via Melbourne)
- **Round-trip bookings**: Use "Return" with primary outbound/inbound flight numbers separated by slash: `2025-03-20 [Lufthansa] London-Tokyo Return LH920/LH456 XYZ123 Liansu.pdf` (outbound: LH920 to Frankfurt, LH456 to Tokyo; return similar pattern)
- **Complex multi-segment**: If booking contains 4+ flights, use first outbound and first inbound flight numbers: `2025-08-10 [Emirates] Paris-Dubai-Paris EK073/EK076 PQR789 Weiwu.pdf`

The date used should always be the departure date of the first outbound flight.

**Examples:**

**Flights and trains:**
- `2025-11-15 [Ryanair] Seville-Porto FR2323 DTF7HZ Liansu,Weiwu,Alice,Zoe.pdf`
- `2025-11-17 [CP] Vila Nova de Gaia-Devesas-Lisbon Santa Apolonia IC130 3835-13392495 Weiwu.pdf`
- `(Cancelled) 2025-11-20 [Ryanair] Porto-Seville FR5544 ABC123.pdf`

**Car rentals** (no flight/train number, use location names):
- `2025-12-25 [Sixt] Edinburgh Airport 9729023889 Liansu.pdf` (same-location rental)
- `2025-11-22 [Enterprise] Lisbon-Porto ABC123 Weiwu.pdf` (multi-city rental)
- `2025-12-26 [Hertz] Berlin Hauptbahnhof-München Airport 30586488 Liansu,Weiwu.pdf` (different pickup/return locations)

### Accommodation Files (in Accommodations folder)

Format: `YYYY-MM-DD Hotel/Property Name BookingRef.pdf`

For cancelled bookings: `(Cancelled) YYYY-MM-DD Hotel/Property Name BookingRef.pdf`

**Required components:**

- **Date**: Check-in date in YYYY-MM-DD format
- **Hotel/Property name**: Full or recognizable name
- **Booking reference**: Confirmation number or booking ID

**Optional components:**

- **Cancellation prefix**: `(Cancelled) ` at the start if the booking was cancelled (note the space after the closing parenthesis)

**Examples:**

- `2025-11-17 Holiday Inn Oporto - Gaia 83910822.pdf`
- `(Cancelled) 2025-11-20 2025-11-15 Casa da Companhia 12345678.pdf`

### Pass Files (in Passes folder)

Format: `YYYY-MM-DD Event/Activity Name [Location] BookingRef.pdf`

For cancelled bookings: `(Cancelled) YYYY-MM-DD Event/Activity Name [Location] BookingRef.pdf`

**Required components:**

- **Date**: Event/activity date in YYYY-MM-DD format
- **Event/Activity name**: Full or recognizable name, e.g., `Web Summit`, `Museum Entry`
- **Location**: City or venue name in square brackets, e.g., `[Lisbon]`, `[Louvre]`
- **Booking reference**: Confirmation number or ticket ID (if applicable, can be omitted for some passes)

**Optional components:**

- **Cancellation prefix**: `(Cancelled) ` at the start if the booking was cancelled (note the space after the closing parenthesis)

**Examples:**

- `2025-11-05 Web Summit [Lisbon] WS2025-12345.pdf`
- `2025-11-18 Louvre Museum [Paris] LV-987654.pdf`
- `(Cancelled) 2025-11-15 Concert [Porto] TKT-456789.pdf`

**Boarding Passes:**

For boarding passes, use format: `Boarding Pass - YYYY-MM-DD [Airline] Origin-Destination PNR.extension`

- Include the PNR/booking reference to link to the corresponding booking in Fares folder
- Examples:
  - `Boarding Pass - 2025-12-01 [Pegasus] Seville-Istanbul 1F6QUT.pdf`
  - `Boarding Pass - 2025-12-04 [IndiGo] Tbilisi-Mumbai XEIUME.jpeg`

### Reimbursement Folders (in journey folder root)

**Format for pending reimbursement folders:**

`Reimburse-Pending (Company Name)`

**Format for completed reimbursement folders:**

`Reimbursed YYYY-MM-DD €Amount (Company Name)`

**Examples:**

- `Reimburse-Pending (Palacio Bizcocheros SL)` - pending reimbursement folder
- `Reimbursed 2025-11-18 €120.99 (Palacio Bizcocheros SL)` - completed reimbursement folder

### Files in Reimbursement Folders

Format: `Type - Vendor Date €Amount.pdf` (invoices, default) or `Type - Vendor Date €Amount (Receipt).pdf` (receipts only)

**Required components:**

- **Type**: Accounting category from the following list (using IFRS):
  - `Travel` - flights, train tickets, bus tickets, car rentals, taxis
  - `Accommodation` - hotels, lodging, rental properties
  - `Conference` - business conferences, trade shows, professional event fees, seminar admissions
  - `Meal` - restaurants, food expenses, catering
  - `Other` - parking, tolls, visas, incidentals
- **Vendor**: Name of vendor, restaurant, or service provider
- **Date**: Invoice/receipt date in YYYY-MM-DD format
- **Amount**: Total amount with euro symbol, e.g., `€120.99`, `€327.90`
- **Document type**: 
  - **Invoice** Document shows tax amount. Tax can be one of a few types: GST, VAT. Add `([tax type]=[currency symbol][tax amount])` suffix to indicate tax amount. Note that even if the invoice says IVA (VAT tax spelt in Spanish or Portogese) the tax type in the filename should still indicate VAT.
  - **Receipt** Document does NOT show tax breakdown, only total amount. Add `(Receipt)` suffix.
- **Extension**: `.pdf` or `.jpg` depending on source

**Examples:**

- `Accommodation - Holiday Inn Express Lisboa Alfragide 2025-11-15 €327.90.pdf`
- `Conference - Web Summit 2025-11-05 €2495.00.pdf`

## Procedure 1: File Organization and Naming

### Purpose

Ensure all files within a journey folder follow established naming conventions and are properly organized in appropriate subfolders. This procedure combines verification, organization, and naming correction into one integrated workflow, creating a systematic foundation for subsequent operations.

### Input

Journey folder (e.g., "2025-01-01 Gold Coast - Liansu; Amsterdam - Liansu, Weiwu, A-Z"). Access via `sop-travel-folder-access.md`.

### Output

Fully organized journey folder with all files compliant to naming conventions

### Steps

1. **Scan Folder Structure**
   - Verify existence of required subfolders: Fares, Passes, Accommodations
   - Note presence of Reimbursement folder(s) if applicable
   - Identify any files at the root level of the journey folder that should be moved to subfolders
   - **Check for messy subfolders**: Look inside `Fares`, `Passes`, and `Accommodations`. These folders should be flat. If you find any sub-subfolders inside them, it means the folder is messy and needs to be cleaned up.

2. **Systematic File Review**
   - For each subfolder (Fares, Passes, Accommodations):
     - List all files
     - Verify each file begins with YYYY-MM-DD date format
     - Check for files without date prefix (orphaned files)
     - Identify files with incorrect date formats (e.g., DD-MM-YYYY, MM/DD/YYYY)
     - For orphaned files or files requiring content verification, extract text:
       - PDF files: Use `pdftotext "filename.pdf" -`
       - Image files (JPG/PNG/JPEG): Use `tesseract "filename.jpg" -` for OCR
     - Verify file content matches the subfolder purpose:
       - **Fares**: Transport documents (flights, trains, buses, car rentals). Indicators: flight numbers, PNR codes, airport codes, departure/arrival times
       - **Passes**: Event tickets, museum entries, activity passes. Indicators: event names, venue names, admission tickets
       - **Accommodations**: Hotel/lodging reservations. Indicators: check-in/check-out dates, room details, hotel names
     - Flag misplaced files for moving to correct subfolder (e.g., a boarding pass in Passes folder should move to Fares)

3. **Fare File Convention Verification**
   - For each file in Fares folder:
     - Verify format matches: `YYYY-MM-DD [Airline] Origin-Destination BookingRef [Optional FF Points] [Optional Passengers].pdf`
     - Check for presence of airline name in square brackets
     - Verify booking reference (PNR, confirmation code) is present
     - Note files missing critical components (airline, booking ref)

4. **Email Account Verification** (if visible in documents)
   - Extract email address from booking confirmations where visible
   - Verify email matches handbook rules:
     - me@weiwu.id.au for Weiwu's family travel (or when requested by Weiwu for Liansu traveling alone)
     - Traveller's email for non-family members
   - Flag any bookings made with incorrect email accounts

5. **Fare File Naming Correction**

   For files requiring correction:

   **a. Information Extraction**
   - Extract text from the document:
     - PDF files: Use `pdftotext "filename.pdf" -`
     - Image files (JPG/PNG/JPEG): Use `tesseract "filename.jpg" -` for OCR
   - Extract the following information:
     - **Cancellation status**: Check if document or related emails indicate this booking was cancelled
     - **Date**: Use the travel/use date, NOT the purchase/booking date
       - For flights/trains: Departure date
       - For car rentals: Pickup date
     - **Transport provider**: 
       - Airlines: Airline name from document header or flight code prefix
       - Trains: Railway company (e.g., CP, DB, SNCF)
       - Car rentals: Company name (e.g., Enterprise, Hertz, Sixt, Avis)
     - **Route**: Determine origin and destination
       - Flights/trains: Airport/station codes or city names
       - Car rentals: Pickup and return locations (may be same)
     - **Flight/Train number**: Extract flight number (e.g., FR1073, SQ265) or train number (e.g., IC130, AVE2991). For buses, car rentals, or transport without fixed numbers, omit this component.
     - **Booking reference**: Extract PNR, confirmation code, or ticket number
     - **Passenger names**: Identify if multiple travelers on same ticket
     - **Frequent flyer program eligibility**: Note flight details for potential FF points verification (flights only, not applicable to car rentals)

   **b. Route Standardization**
   - Format route as: `Origin-Destination` using hyphens
   - For multi-segment routes: `Origin-Stop-Destination` (use hyphens between segments)
   - For return flights: `Origin-Destination Return`
   - For car rentals with same pickup/return location: Use location name once (no hyphen)
   - Use full city names or recognizable location names (e.g., "Edinburgh Airport", "Berlin Hauptbahnhof")
   - For flights/trains, airport/station codes are acceptable if they're standard convention (e.g., "Singapore-Brisbane" not "SIN-BNE" unless widely recognized)

   **c. Frequent Flyer Points Assessment** (Optional)
   - If FF transaction history available, check if flight is recorded:
     - If claimed: Note program and points amount: `(ProgramName +Points)`
     - If eligible but not claimed: Note as: `(ProgramName!)`
   - If no history available, skip FF notation
   - Only include FF notation when relevant (not all flights are eligible or worth tracking)

   **d. Passenger Name Inclusion Decision** (Optional)
   - Include passenger names when:
     - Multiple travelers on same ticket
     - Useful for distinction between similar bookings
     - Names help identify ticket ownership
   - Format: `Weiwu,Zoe,Alice` (comma-separated, no spaces)
   - Use established abbreviations when appropriate (e.g., `A-Z` for Alice and Zoë)

   **e. Filename Construction**
   - Assemble components in order:
     - Cancellation prefix (if applicable): `(Cancelled) `
     - Date (YYYY-MM-DD)
     - Space
     - Airline in square brackets: `[Airline]`
     - Space
     - Route: `Origin-Destination`
     - Space
     - Flight/Train number (if applicable): `FR1073` or `IC130`
     - Space
     - Booking reference (no special formatting)
     - Space (if FF points included)
     - FF points notation in parentheses (if applicable): `(Qantas +3500)` or `(Qantas!)`
     - Space (if passengers included)
     - Passenger names (if applicable)
     - File extension: Preserve original (`.pdf`, `.jpg`, `.jpeg`, `.png`)

   **f. Format Validation**
   - Verify filename matches convention exactly
   - Check for proper spacing between components
   - Verify square brackets around airline name
   - Verify flight/train number is present (if applicable - omit for buses, car rentals)
   - Verify parentheses around FF notation (if included)
   - Ensure booking reference is present

6. **Reorganization Actions**
   - Move misplaced files to correct subfolders based on content (as identified in Step 2)
   - Move orphaned files to appropriate subfolders with correct date prefix
   - Rename files with incorrect date formats (use date from document content, not filename)
   - Apply fare file naming correction as described in Step 5
   - For reimbursement files requiring naming correction, apply Helper Procedure A
   - **Clean up messy subfolders**: If you found any sub-subfolders in Step 1, move everything out of them into the main category folder (like `Passes`). Once the subfolders are empty, delete them so the category folder stays flat.

7. **Checkpoint: Organization and Naming Complete**
   - All files are in correct subfolders based on content type
   - All files follow YYYY-MM-DD date format prefix
   - All fare files include airline name in square brackets
   - All fare files include booking reference
   - No orphaned files remain
   - Email account usage (where visible) matches handbook rules
   - All files are correctly named and readable

## Procedure 2: Checking Email and Ensuring Files Are Saved

### Purpose

Verify that all booking confirmation emails (transport and accommodation) have been saved to the journey folder, identify and save airline and hotel invoices to appropriate reimbursement folders, and identify promotional/informational emails that can be deleted for journeys that have already occurred.

### Prerequisites

- Access travel folders following `sop-travel-folder-access.md`
- The `imap-mcp` MCP server must be pre-configured and working in Cursor to access the email inbox
- **Check current date** at the start of execution (use system date/time information available in the environment)

### Input

Journey folder (access via `sop-travel-folder-access.md`)

### Output

Action list for user confirmation containing:

- Emails to delete (with UID, folder, subject for execution without re-searching)
- Missing transport booking confirmations to save
- Missing accommodation booking confirmations to save
- Hotel invoices to save to reimbursement folders (with reimbursement folder creation if needed)
- File naming corrections needed

### Steps

1. **Determine Current Date and Journey Status**
   - Note the current date from system information
   - Extract journey dates from folder name
   - Determine if journey is: Past (can delete promotional emails) | Current/Future (retain all emails)

2. **Collect All Booking References from Fares Folder**
   - List all files in the Fares subfolder
   - Extract and record all booking references/PNR codes from filenames:
     - Airline tickets: PNR codes but sometimes (e.g. Airlines in China) Ticket IDs.
     - Other transport: Ticket IDs or Confirmation numbers
   - Extract travel dates from filenames (YYYY-MM-DD prefix)
   - Note which airlines/transport providers are involved
   - **Create a reference list** before proceeding to email search

3. **Collect All Accommodation Bookings from Accommodations Folder**
   - List all files in the Accommodations subfolder
   - Extract and record all hotel booking information from filenames:
     - Check-in dates (YYYY-MM-DD prefix)
     - Hotel/property names
     - Booking references/confirmation numbers
   - **Create an accommodation reference list** before proceeding to email search
   - Note the start and end dates of the journey (earliest check-in to latest check-out or travel end)

4. **Search Emails for Travel Bookings and Taxi Invoices**

   **Search Method**:
   
   General approach for all searches (you wont save any time by writing a script to search here):
   
   - **Performance**: Use `from` and `subject` criteria first (faster than `text` search). The `from` criteria searches only email headers, while `text` searches full email body content. Only fallback to `text` search if results are incomplete.
   - **CRITICAL - Multiple name variations**: If a company has multiple names (e.g., "CP" vs "Comboios de Portugal"), run SEPARATE searches for each variation. DO NOT combine variations in one search string (e.g., searching "CP Comboios" only matches if both words appear together - net in 0 results. Search "CP" separately, then search "Comboios" separately.)
   - **Date filtering**: Only examine emails where the email date is within or near the journey date range (from earliest travel date minus 120 days to latest travel date plus 7 days). This reduces false positives from unrelated bookings.
   - **Search limit**: Use reasonable limit (50 emails per provider should be sufficient)
   - **INBOX Sanity Check** (if multiple searches return empty):
     - If 3 or more consecutive searches return empty results `[]`, perform sanity check:
       - Search for common word: `criteria: "subject"`, `query: "the"`, `limit: 10`
       - If this returns empty `[]`: **BAIL OUT** - cite abnormal INBOX behavior, INBOX may be empty or IMAP server may be malfunctioning
       - If this returns results: Continue with procedure, empty results were legitimate
     - This check prevents wasting time on a non-functional INBOX
   
   For each search:
   - **By subject**: `criteria: "subject"` with provider/hotel name or common keywords
   - **By sender**: `criteria: "from"` with provider/hotel name or domain
   - **Fallback**: `criteria: "text"` with booking references (slower, use only if needed)

   **a. Airlines and Transport Providers**:
   - Extract provider names from Fares folder filenames (text within square brackets)
   - **Subject keywords specific to transport**: "Tickets", "Ticket", "Itinerary", "booking", "confirmation"
   - **Sender examples**: Airline/transport name or abbreviation (e.g., "Ryanair", "cp.pt")
   - **Fallback text search**: Use PNR codes or ticket IDs from Fares folder

   **b. Car Rental Bookings**:
   - **Purpose**: Find car rental bookings that may not yet be saved to Fares folder
   - **Common providers to search**: Enterprise, Hertz, Sixt, Avis, Budget, Europcar, Alamo, National
   - **Search method**: Search by sender for each provider separately
     - `criteria: "from"`, `query: "enterprise"` 
     - `criteria: "from"`, `query: "hertz"`
     - `criteria: "from"`, `query: "sixt"`
     - `criteria: "from"`, `query: "avis"`
     - `criteria: "from"`, `query: "budget"`
     - Continue for other major providers as needed
   - **Also search by subject** for generic car rental terms:
     - `criteria: "subject"`, `query: "car hire"` (common UK/EU term)
     - `criteria: "subject"`, `query: "car rental"`
   - **Confirmation priority**: If both an OTA confirmation (e.g., Expedia) and a direct provider confirmation (e.g., Avis) exist for the same booking, prefer the direct provider confirmation.
   - **Date filtering**: Apply journey date range filtering (booking date or rental dates within journey range)
   - **Note**: Car rentals may be same-location (pickup and return at same place) or multi-city. Both types should be captured.

   **c. Accommodation Bookings**:
   - Extract hotel names and booking references from Accommodations folder filenames
   - **Subject keywords specific to accommodation**: "booking", "confirmation", "reservation", "hotel", **"invoice", "folio"**
   - **Sender examples**: Hotel names or booking platform names (e.g., "IHG", "Booking.com", "ihg.com"). Try both commercial name and domain name. **Also search for hotel-specific emails** by searching for any emails from a hotel domain.
   - **Fallback text search**: Use booking references from Accommodations folder
   - **CRITICAL**: Search for BOTH booking confirmations AND invoices. Hotels often send invoices from different email addresses (front desk emails) than booking confirmations. Booking confirmations show what was planned; invoices show what was actually charged.

   **d. Taxi and Ride-Hailing Invoices** (Reimbursement Filing Only):
   - **Purpose**: Find all taxi/ride-hailing trip receipts and invoices within the journey date range for reimbursement filing
   - **Timing context**: Taxi trips are not typically pre-planned, so search must cover the entire journey date range (from earliest travel date to latest travel date)
   - **Subject keywords specific to taxi/ride-hailing**: "receipt", "invoice", "trip", "ride"
   - **Sender examples**: Ride-hailing app names or domains (e.g., "Uber", "uber.com", "Bolt")
   - **Search each provider separately**: 
     - Search "Uber" by sender (criteria: "from", query: "uber")
     - Search "Bolt" by sender (criteria: "from", query: "bolt")
   - **Date filtering**: Only examine emails where the trip date falls within the journey date range (from earliest travel date to latest travel date)
  - **Special Case - Bolt invoice downloads**: 
    Bolt invoices are typically provided as download links in the email body, not as attachments. For each Bolt email UID, use the MCP `extract_email_links` tool (parameters: folder and uids) to get all links from the emails in one batch, identify the Bolt invoice URL (look for URLs containing "bolt" and "invoice" or "receipt"), then download the invoice using wget or similar download tool to the reimbursement folder before extracting invoice details and renaming per Helper Procedure A.
   - **Organisation name handling**:
     - If taxi invoices do NOT include organisation/company names, save these invoices to the reimbursement folder still. This is because most countries allow small invoices to not mention client company name.
     - **If there are multiple active reimbursement folders** (rare case where 2 companies are involved):
       - Check which company paid for the hotel accommodation on the same date as the taxi trip
       - The company paying the hotel that day is the company that should reimburse the taxi trip
       - Save the taxi invoice to that company's reimbursement folder
   - **Saving format**: Apply Helper Procedure A for file naming (see Helper Procedure A for detailed naming conventions)

5. **Categorize Each Email**
   
   For each email found (from airline/transport, car rental, accommodation, and taxi/ride-hailing searches), determine:

   **a. Is it related to this journey?**
   - **Manual matching**: Read the email content (subject and body) and check if it contains any PNR codes from the reference list (Step 2) or accommodation booking references from the accommodation reference list (Step 3)
   - **For car rental emails**: Check if the rental dates (pickup or return date) fall within the journey date range (from earliest travel date minus 7 days to latest travel date plus 7 days). Car rentals are often booked slightly before or after main journey dates.
   - **For taxi/ride-hailing emails**: Check if the trip date falls within the journey date range (from earliest travel date to latest travel date)

   **b. What type of email is it?**
   
   **For Transport Bookings:**
   - **Booking Confirmation** (Travel Itinerary, Reservation Confirmation, Invoice with PNR):
     - Subject typically: "Travel Itinerary", "Booking Confirmation", "Invoice [number]"
     - Contains full booking details
     - **Action**: Verify if already saved in Fares folder. If not, flag for saving.
   
   - **Cancellation Confirmation**:
     - Subject typically: "Cancellation confirmed", "Booking cancelled", "Refund processed"
     - Confirms that a booking has been cancelled
     - **Action**: 
       - Verify if the corresponding booking file exists in Fares folder
       - If it exists without "(Cancelled)" prefix, flag for renaming with "(Cancelled)" prefix
       - If cancellation email includes an invoice (refund details, cancellation fees), flag for saving even if cancelled
   
   - **Additional Information** (Promotional, tips, reminders):
     - Subject typically: "Flying with kids?", "Bring the right bag", "Do you need extra bags?", "Win a gift card", "Questions about booking?"
     - Does NOT contain booking confirmation
     - Informational only, not required for travel
     - **Action**: If journey is in the past, flag for deletion. If journey is current/future, retain.
   
   - **Check-in Reminder**:
     - Subject typically: "Check in online for your flight"
     - Reminds traveler to check in
     - **Action**: If travel date has passed, flag for deletion. If travel date is future, retain.
   
   - **Important Updates** (Flight changes, schedule modifications):
     - Subject typically: "Important update", "Flight change", "Schedule modification"
     - Contains critical information about booking changes
     - **Action**: Always verify if saved. If travel has passed and no changes were made, can flag for deletion.
   
   **For Car Rental Bookings:**
   - **Rental Agreement / Booking Confirmation**:
     - Subject typically: "Rental Agreement", "Booking confirmed", "Your reservation", "Confirmation #", "car hire confirmation"
     - Contains booking reference, pickup/return dates and locations, vehicle details
     - **Attachments**: If the email has attachments, extract and examine them for booking details.
     - **Confirmation priority**: If both an OTA confirmation (e.g., Expedia) and a direct provider confirmation (e.g., from Avis itself) exist for the same booking, prefer the direct provider confirmation.
     - **Extract key information**:
       - Booking reference/confirmation number (use the car rental company's reference, not OTA's)
       - Pickup date and location
       - Return date and location (may be same as pickup)
       - Company name (the actual car rental company, e.g., Avis, not the OTA)
       - Passenger/renter name
     - **Action**: Check Fares folder for duplicate using multiple criteria:
       - **Primary check**: Search for any file containing the booking reference in its filename
       - **Secondary check** (if no booking ref match): Search for files matching BOTH:
         - The pickup date (YYYY-MM-DD format at start of filename)
         - AND the company name (e.g., "Sixt", "Enterprise", "Hertz", case-insensitive)
       - **If found with correct name** (matching convention below): Skip saving
       - **If found with incorrect name**: Flag for renaming instead of saving, note what was found
       - **If not found by either check**: Flag for saving using car rental naming convention (see below)
     - **Example duplicate detection**:
       - Email has: Sixt booking #9729023889, pickup 2025-12-25, Edinburgh Airport
       - Fares folder has: `2025-12-25 Sixt Car Rental.pdf` (incomplete name)
       - Result: Match found via date+company → Flag for renaming to `2025-12-25 [Sixt] Edinburgh Airport 9729023889 Liansu.pdf`
   
   - **Prepayment Invoice**:
     - Subject typically: "Prepayment invoice", "Invoice for booking"
     - Contains invoice details for a car rental booking
     - **Action**: May contain same information as booking confirmation. If booking confirmation already saved, skip. Otherwise, save as booking confirmation.
   
   - **Promotional / Reminder Emails**:
     - Subject typically: "Check in before pickup", "Access code", "Questions about your rental"
     - Does NOT contain full booking details
     - **Action**: If journey is past, flag for deletion. If future, retain.
   
   **Car Rental Filename Convention**:
   When saving car rental bookings, apply this naming format:
   ```
   YYYY-MM-DD [Company] PickupLocation-ReturnLocation BookingRef Passengers.pdf
   ```
   
   **Special cases**:
   - If pickup and return locations are the same:
     ```
     YYYY-MM-DD [Company] Location BookingRef Passengers.pdf
     ```
   - Use pickup date as the YYYY-MM-DD prefix
   - Use recognizable location names (e.g., "Edinburgh Airport" not "EDI T1 Desk 5")
   - Omit flight/train number component (car rentals don't have these)
   
   **Examples**:
   - `2025-12-25 [Sixt] Edinburgh Airport 9729023889 Liansu.pdf` (same-location rental)
   - `2025-12-26 [Enterprise] Berlin-Munich 26LGYL Weiwu.pdf` (multi-city rental)
   - `2025-12-29 [Hertz] Vienna Airport-Warsaw Airport 30586488 Liansu,Weiwu.pdf` (airport-to-airport)
   
   **For Accommodation Bookings:**
   - **Hotel Booking Confirmation**:
     - Subject typically: "Booking confirmation", "Reservation confirmed", "Your booking at [Hotel Name]"
     - Contains booking reference, hotel name, check-in/check-out dates
     - **CRITICAL: Verify check-in date falls within journey date range** (from earliest travel date to latest travel date + 7 days). If check-in is outside this range, this booking belongs to a different journey - skip it.
     - **Action**: Verify if already saved in Accommodations folder. If not, flag for saving.
     - **Check for invoice**: Examine if the email contains an invoice attachment or invoice information
   
   - **Cancellation Confirmation**:
     - Subject typically: "Cancellation confirmed", "Booking cancelled", "Reservation cancelled"
     - Confirms that an accommodation booking has been cancelled
     - **Action**: 
       - Verify if the corresponding booking file exists in Accommodations folder
       - If it exists without "(Cancelled)" prefix, flag for renaming with "(Cancelled)" prefix
       - If cancellation email includes an invoice (refund details, cancellation fees), flag for saving even if cancelled
   
   - **Hotel Booking with Invoice**:
     - If email contains an invoice (as attachment or embedded):
       - **Extract company name** from invoice (billing entity, not hotel brand name)
       - **Check for existing reimbursement folder**: Look for folder named `Reimburse-Pending (Company Name)` in the journey folder. If any completed reimbursement folders exist with format `Reimbursed YYYY-MM-DD €Amount (Company Name)`, check those as well to see if the invoice has already been downloaded. Skip downloading if the invoice already exists in any reimbursement folder.
       - **Action**: Flag for saving invoice to appropriate reimbursement folder (create folder if needed), unless invoice already exists
   
   - **Hotel Promotional/Marketing**:
     - Subject typically: "Special offers", "Upcoming stay", "Rate your stay", "Earn bonus points"
     - Does NOT contain booking confirmation
     - **Action**: If journey is in the past, flag for deletion. If journey is current/future, retain.

   **For Taxi/Ride-Hailing Invoices:**
   - **Trip Receipt/Invoice** (Uber, Bolt):
     - Subject typically: "Your trip receipt", "Your Uber receipt", "Your trip with Bolt", "Your receipt from [date]"
     - Contains trip details: date, origin, destination, fare amount
     - **Action**:
       - Verify trip date falls within journey date range
       - Flag for saving to appropriate reimbursement folder
       - Apply Helper Procedure A for file naming
   
6. **Cross-Reference Files with Emails**

   After processing all emails, note which files in the journey folder have no corresponding email. This is informational tracking only—files without emails are valid and should not be deleted or flagged as problems.

   For each file in Fares, Accommodations, and Passes folders (excluding cancelled bookings):

   - Check if a corresponding email was found during the searches above
   - If no email was found, note in the report: "No email match for [filename]"
   - This is expected when files were saved from WhatsApp, photographed from physical documents, forwarded from another traveler's mailbox, or when the confirmation email was deleted or sent to a different account

   **Note on Cancellations:**

   - Cancelled bookings (with "(Cancelled)" prefix) are excluded from this cross-reference
   - However, if a cancellation email mentions an invoice (refund details, cancellation fees), this should still be saved

7. **Identify Missing Invoices**

   For bookings that require reimbursement, check whether the tax invoice (not just the booking confirmation) has been saved. A tax invoice is a document showing VAT/GST/IVA breakdown—booking confirmations, tickets, and reservation details are not invoices.

   - For each booking in a journey with active reimbursement folders:
     - Check if a corresponding tax invoice exists in the reimbursement folder
     - If no invoice exists: note in the report as "Missing invoice for [booking reference]"
   - Common cases: hotel invoices (sent after checkout), airline invoices (for business travel), car rental invoices

8. **Generate Action List**

   Create list with sufficient detail for execution without re-searching. For each action, provide:

   **For Saving Files**:
   - **Re-runnability check**: Before flagging a file for saving, check if the booking already exists in the target folder using multiple criteria
     - **For flights/trains**: Search Fares folder for files containing the booking reference/PNR OR (date + airline/rail company match)
     - **For car rentals**: Search Fares folder for files containing the booking reference OR (pickup date + company name match)
     - **For accommodation bookings**: Search Accommodations folder for files containing the booking reference OR (check-in date + hotel name match)
     - **For reimbursement files**: Search reimbursement folders for files matching (vendor + date) OR (vendor + amount)
   - **If file exists with correct name**: Skip saving (file was saved in a previous RUN, no action needed)
   - **If file exists with incorrect name**: Flag for renaming instead of saving, include current filename in action
   - **If file does not exist by any check**: Flag for saving
   - UID: [number] and Folder: [folder name] (to locate the email)
   - Target: [folder path]/[filename following naming convention]
   - Special notes: [if needed, e.g., "Create reimbursement folder if needed", "Rename existing file [current name]"]
   
   **For Renaming Files**:
   - Current: [folder path]/[current filename]
   - New: [folder path]/[new filename]
   
   **For Deleting Emails**:
   - UID: [number] and Folder: [folder name]
   - Reason: [e.g., "Promotional - journey completed"]
   
   **For Files Without Email Match** (informational only):
   - File: [filename] in [folder]
   - Note: No corresponding email found (file may have been saved from WhatsApp, photo, or another source)
   
   **For Missing Invoices** (for reimbursement tracking):
   - Booking: [reference] in [folder]
   - Issue: No tax invoice found in reimbursement folder
   
   **Notes on file naming**:
   - Apply Procedure 1 naming conventions for Fare files
   - Apply accommodation naming convention for hotel bookings
   - Apply Helper Procedure A for reimbursement files (hotel invoices, taxi invoices)
   - Taxi invoices: `Travel - [Provider] [Date] €[Amount].(VAT=€X.XX or Receipt).pdf`

9. **Execute Actions**
   - Group actions by type: File Saves | File Renames | Email Deletions | Files Without Email Match | Missing Invoices
   - Include journey status (past/current/future) in summary
   - Execute file saves and renames
   - Report what was done

### Important Notes

- **Search performance**: The `from` and `subject` criteria are faster than `text` search. Always use `from`/`subject` first, only fallback to `text` search when specific emails appear to be missing from header-based searches.
- **Never delete emails for current or future travel** - only delete promotional/informational emails for completed journeys
- **Always retain booking confirmations** - even for past travel, these are records (both transport and accommodation)
- **Retain "Important Update" emails** - these may contain critical information about changes
- **Cancellations require file renaming** - when a cancellation email is found, rename the corresponding booking file with "(Cancelled)" prefix
- **Cancellation invoices should still be saved** - even if a booking is cancelled, save any invoice that comes with the cancellation (refund details, cancellation fees). This is especially common with airlines
- **Action list must be self-contained** - include UID and folder (to locate email) and target folder/filename (where to save). File naming follows existing procedures (Procedure 1 for fares, Helper Procedure A for reimbursements).
- **Invoice extraction**: When processing accommodation emails with invoices, extract the company name from the invoice document itself, not from the email subject or hotel brand name. The company name is the legal billing entity shown on the invoice.
- **Reimbursement folder naming**: Use exact company name from invoice when creating or identifying reimbursement folders. Multiple hotels may be billed by the same company, so multiple hotel invoices may go into the same reimbursement folder.
- **Date range filtering for accommodation searches**: Use journey date range ± 60 days to filter accommodation emails, reducing false positives from unrelated bookings from different trips.
- **Empty INBOX detection**: If multiple searches return empty and the sanity check (searching for "the" in subject) also returns empty, the INBOX is genuinely empty or IMAP is malfunctioning. Do not continue the procedure.
- **Taxi/ride-hailing invoices**: These are specific to reimbursement filing and are not pre-planned bookings. Search for these across the entire journey date range. Invoices often lack company/organisation names, which is acceptable - save them anyway.
- **Multiple reimbursement folders (rare)**: If multiple active reimbursement folders exist when saving taxi invoices, determine which company should reimburse by checking which company paid for the hotel on the same date as the taxi trip.

### Checkpoint: Email Verification Complete

- INBOX sanity check passed (if multiple searches returned empty, sanity check confirmed INBOX has emails)
- All PNR codes/booking references collected from Fares folder
- All accommodation booking references collected from Accommodations folder
- Journey date range established
- Current date determined and journey status assessed
- Search strategy applied: `from`/`subject` criteria used first, `text` search used as fallback only when needed
- All emails categorized appropriately (transport, accommodation, and taxi/ride-hailing)
- Taxi/ride-hailing invoices identified within journey date range
- Cancellation emails identified and corresponding files flagged for renaming
- Files without email match noted for informational tracking
- Missing invoices identified for reimbursement tracking
- Hotel invoices identified and company names extracted
- Taxi/ride-hailing invoices assigned to appropriate reimbursement folders (considering multiple folder scenarios)
- Reimbursement folders identified or flagged for creation
- Action list generated with sufficient detail for execution
- User confirmation requested before any actions

## Helper Procedures

These procedures are called from multiple main procedures and provide specialized functionality for specific tasks.

### Helper Procedure A: Reimbursement File Naming with Tax Extraction

**Purpose**

Correctly name reimbursement files following the established convention with accurate tax amount extraction. This procedure distinguishes between invoices (documents with tax breakdown) and receipts (documents without tax breakdown). Tax amounts must be extracted by reading each invoice manually—invoices have no uniformity in format or structure, and automated extraction will fail.

This helper procedure is called from:
- Procedure 1 (File Organization): When reimbursement files exist but require correct naming
- Procedure 2 (Email Checking): When saving hotel invoices or taxi invoices from emails to reimbursement folders

**Input**

PDF or image file in a reimbursement folder requiring proper naming

**Output**

Properly named file following convention:
- **Invoice**: `Type - Vendor Date €Amount (VAT=€TaxAmount).extension`
- **Receipt**: `Type - Vendor Date €Amount (Receipt).extension`

**Steps**

1. **Extract Document Text**
   - Use `pdftotext` to extract text from PDF: `pdftotext "filename.pdf" -`
   - If text extraction yields no results or very limited text (image-based PDF), proceed to OCR
   - For JPG/PNG files, proceed directly to OCR

2. **OCR for Image-Based Documents**
   - Convert PDF to image if needed: `pdftoppm "filename.pdf" temp -png -f 1 -l 1`
   - Run OCR: `tesseract temp-1.png -` (or directly on JPG/PNG files)
   - Clean up temporary files: `rm -f temp-*.png`

3. **Determine Document Type: Invoice vs Receipt**
   
   **Invoice criteria**: Document shows tax amount breakdown with any of these indicators:
   - VAT (Value Added Tax)
   - IVA (VAT in Spanish/Portuguese)
   - GST (Goods and Services Tax)
   - Sales tax itemisation
   - Tax rate percentage (e.g., "13%", "23%", "6%") with corresponding tax amount
   
   **Receipt criteria**: Document does NOT show tax breakdown:
   - Only shows total amount
   - May say "IVA INCLUIDO" (VAT included) but doesn't itemise the tax amount
   - May say "ESTE TALAO NAO SERVE COMO FATURA" (This slip does not serve as invoice)
   
   **Key distinction**: If tax amount is separately itemised, it's an invoice. If tax is only mentioned as "included" without breakdown, it's a receipt.
   
   **CRITICAL: NEVER rename a receipt to appear as an invoice**
   - If a document is a receipt (no tax breakdown), it MUST be named with `(Receipt)` suffix
   - If a document is an invoice (has tax breakdown), it MUST be named with `(VAT=€X.XX)` or `(GST=€X.XX)` suffix
   - NEVER change `(Receipt)` to `(VAT=€0.00)` or vice versa
   - The document type determines the naming, not your preference or interpretation
   - Even if you think a receipt "should" show tax, if the document doesn't itemise it, it remains a receipt

4. **Manual Tax Amount Extraction**

   **DO NOT WRITE A SCRIPT TO EXTRACT TAX AMOUNTS. DO NOT.**
   
   Read the invoice. Extract the tax amount manually without writing an extraction script. This is not optional. This is not a suggestion. This is how you do this job.
   
   Why? Because invoices are chaos:
   
   - No two vendors format invoices the same way
   - PDFs are unstructured text dumps—no guaranteed format, no guaranteed structure
   - Tax terminology varies wildly across EU languages: VAT, IVA, TVA, MwSt, BTW, MOMS, ΦΠΑ, ALV, DPH, ДДС, PVM, and hundreds more
   - Scripts fail unless tested against tens of thousands of diverse invoices—you don't have tens of thousands of test cases
   - Scripts that work on 90% of invoices still fail on 10%, creating silent errors you won't catch until audit time
   - We are using AI here precisely because you can read, understand context, and handle chaos — scripts cannot
   
   **What you MAY do**: Use `grep` to search for tax keywords (VAT, IVA, GST, Tax, Imposto, etc.) to locate the relevant section of the text. 
   
   **What you MUST do after grep**: Read the surrounding text manually. Identify the tax amount by reading. Extract it by reading. Verify it makes sense by reading.
   
   **If grep finds nothing**: Read the entire invoice. Tax might be spelled in ways you didn't search for. Tax might be formatted unusually. Tax might be embedded in paragraphs rather than tables. The absence of keywords does not mean absence of tax—only reading the document confirms this.

   **Invoice Formats You Might Encounter** (examples only—real invoices will vary):

   Invoices present tax information in countless ways. Here are three common patterns, but treat each invoice as unique:

   **Format A: Tax as Row in Table**
   ```
   Total:                    17,00 Euro
   IVA INCLUIDO
   
   Incidencia    IVA%    IVA
   15,04         13%     1,96
   ```
   Read the table. Find the tax keyword (IVA, VAT, GST, etc.). Read the value in that row.
   In this example: IVA = **€1.96**

   **Format B: Tax as Column in Table**
   ```
   Taxa    Base     IVA      Total
   13.00   €10.49   €1.36    €11.85
   ```
   Read the table headers. Find the tax column. Read the value in that column. If multiple rows exist, read each one and sum them manually.
   In this example: IVA = **€1.36**

   **Format C: Multiple Tax Rates**
   ```
   Taxa    Base     IVA      Total
   13.00   €23.01   €2.99    €26.00
   23.00   €2.44    €0.56    €3.00
   ```
   Read all rows. Add all tax amounts yourself: €2.99 + €0.56 = **€3.55**
   
   These are examples. Your invoice might look completely different. Tables might be sideways. Numbers might use commas instead of periods. Tax might be called something else. Column headers might be in another language. The layout might be nonsensical. Read it anyway. Figure it out.

5. **Extract Invoice/Receipt Details**
   
   From document text/OCR, extract:
   - **Vendor name**: Business name at top of document or in header
   - **Date**: Look for date format YYYY-MM-DD, DD-MM-YYYY, or DD/MM/YYYY
     - Convert to YYYY-MM-DD format for filename
     - Search for keywords: "Data", "Date", "Emitida em"
   - **Total amount**: Final amount paid
   - **Tax amount** (if invoice): Extracted using methods above
   - **Document type**: Invoice (if tax breakdown exists) or Receipt (if no tax breakdown)

6. **Determine Accounting Category**
   
   Based on vendor type and document content, categorise as:
   - **Travel**: Flights, train tickets, bus tickets, car rentals, taxis (unless taxi is private hire)
   - **Accommodation**: Hotels, lodging, rental properties. **IMPORTANT**: Hotel folios that include accommodation charges plus incidental meals/minibar/etc should be categorised as Accommodation, not Meal. The primary service (accommodation) determines the category.
   - **Conference**: Business conferences, trade shows, professional event fees
   - **Meal**: Restaurants, food expenses, catering (standalone meal charges, not part of hotel folio)
   - **Other**: Parking, tolls, visas, incidentals, taxi (private hire)

7. **Tax Type Normalisation**
   
   - If document shows "IVA" (Spanish/Portuguese VAT), use **VAT** in filename
   - If document shows "GST", use **GST** in filename
   - If document shows "VAT", use **VAT** in filename
   - If document shows "Sales Tax", use **GST** in filename (normalise to GST)

8. **Filename Construction**

   **For Invoices** (with tax breakdown):
   ```
   Type - Vendor Date €Amount (TaxType=€TaxAmount).extension
   ```
   
   Examples:
   - `Meal - Sushi Tsukuri 2025-11-14 €17.00 (VAT=€1.96).pdf`
   - `Other - Lisbon Airport Parking 2025-11-18 €45.00 (VAT=€8.28).pdf`
   
   **For Receipts** (no tax breakdown):
   ```
   Type - Vendor Date €Amount (Receipt).extension
   ```
   
   Examples:
   - `Meal - Quick Lunch Cafe 2025-11-12 €8.50 (Receipt).jpg`
   - `Other - Metro Ticket 2025-11-13 €2.50 (Receipt).pdf`

9. **Special Cases**

   **Zero-rated/Exempt Items** (flights, international services):
   - If document shows tax line but amount is €0.00, still use invoice format
   - Example: `Travel - Ryanair Dublin-Lisbon 2025-11-10 €89.99 (VAT=€0.00).pdf`
   
   **OCR Reading Errors**:
   - If OCR misreads tax amount (e.g., "1.96" as "1,96" or "l.96"), correct to proper format
   - Verify tax amount makes sense relative to total (typically 6%, 13%, 23% rates in Portugal/Spain)
   - If OCR confidence is low, manually inspect image file
   
   **Mixed Rates** (e.g., restaurant with food at 13% and beverages at 23%):
   - Always sum all tax amounts
   - Example: Food IVA €2.34 + Beverage IVA €1.15 = Total VAT €3.49

10. **Format Validation**
    - Verify filename follows exact convention
    - Check proper spacing: `Type - Vendor Date €Amount (Suffix)`
    - Verify date is YYYY-MM-DD format
    - Verify amount has euro symbol: €XX.XX (two decimal places)
    - Verify tax suffix format: `(VAT=€XX.XX)` or `(GST=€XX.XX)` or `(Receipt)`
    - Verify no forbidden characters for Windows: no `:` `/` `\` `*` `?` `"` `<` `>` `|`

11. **Rename Action**
    - Rename file to constructed filename
    - Verify file is readable after rename

**Checkpoint: Reimbursement File Naming Complete**

- Document type determined (invoice with tax vs receipt without tax)
- Tax amount accurately extracted (considering table format and multiple rates)
- Vendor, date, and amount extracted correctly
- Accounting category assigned appropriately
- Tax type normalised (IVA → VAT)
- Filename follows exact convention with Windows-compatible characters
- File renamed and verified accessible

## Appendix A: Format Validation Examples

### Correct Fare File Naming Examples

✅ `2025-01-01 [Transavia] Seville-Amsterdam HV6728 HDKEVG.pdf`
- Date in YYYY-MM-DD format
- Airline in square brackets
- Route with hyphen
- Flight number included
- Booking reference included

✅ `2025-06-18 [Singapore Airlines] Singapore-Brisbane SQ265 5PG9NY (AirCanada!).pdf`
- Includes flight number
- FF notation in parentheses (unclaimed)
- All required elements present

✅ `2025-10-07 [LATAM] Santiago-Melbourne-Brisbane LA805 OSGGXG (Qantas +3500).pdf`
- Multi-segment route with hyphens
- Flight number included
- FF notation with claimed points
- Booking reference included

✅ `2025-04-04 [Plus Ultra] Madrid-Lima Return PU900 VYOXWI Liansu,Alice.pdf`
- Return flight indicated
- Flight number included
- Multiple passengers included
- Proper comma separation

✅ `(Cancelled) 2025-11-20 [Ryanair] Porto-Seville FR5544 ABC123.pdf`
- Cancellation prefix at start
- Flight number included
- All other naming conventions followed
- Space after closing parenthesis

✅ `2025-11-17 [CP] Vila Nova de Gaia-Devesas-Lisbon Santa Apolonia IC130 3835-13392495 Weiwu.pdf`
- Train number included (IC130)
- Long station names properly formatted
- Booking reference included

### Incorrect Fare File Naming Examples

❌ `2023-03-30 Aiqin's tourist ticket from Beijing to Moscow - China Southern.pdf`
- Missing airline brackets
- Using "to" instead of hyphen
- Missing flight number
- Missing booking reference
- Passenger name at start instead of end

❌ `2025-01-01 1. Sevilla to Amsterdam HV-6728 HDKEVG.pdf`
- Using "to" instead of hyphen
- Missing airline brackets
- Numbered prefix unnecessary
- Flight number should be HV6728 (no hyphen in flight number)

❌ `2025-03-10 Sydney - Gold Coast.pdf`
- Missing airline name
- Missing flight number
- Missing booking reference
- Incomplete information

❌ `Cancelled 2025-11-20 [Ryanair] Porto-Seville FR5544 ABC123.pdf`
- Incorrect cancellation format (missing parentheses)
- Should be: `(Cancelled) 2025-11-20 [Ryanair] Porto-Seville FR5544 ABC123.pdf`

❌ `2025-11-15 [Ryanair] Seville-Porto DTF7HZ Liansu,Weiwu,Alice,Zoe.pdf`
- Missing flight number between route and booking reference
- Should be: `2025-11-15 [Ryanair] Seville-Porto FR2323 DTF7HZ Liansu,Weiwu,Alice,Zoe.pdf`

## Next Steps: Journey Evaluation and Itinerary Generation

After completing folder management RUN, you may proceed to journey completeness evaluation and itinerary generation:

**Travel Itinerary Management SOP** (`travel-itinerary-management.md`)

This separate SOP handles:

- **Mental journey simulation**: Step through the journey to identify gaps in transport connections, accommodation continuity, and timing issues
- **Completeness evaluation**: Categorise gaps by severity (genuine gaps, acceptable gaps, verification needed) using contextual reasoning
- **Itinerary document generation**: Create or update Itinerary.md with integrated completeness checklist, transportation table, and day-by-day timeline with estimated timestamps
- **Booking recommendations**: Provide guidance on options and considerations for identified gaps

**When to use itinerary management:**

- After folder management completes and files are organised
- When journey evaluation is needed before departure
- When itinerary updates are required due to booking changes
- When user requests completeness assessment

**Why separate?**

The separation allows:

- Folder management can run automatically without user interaction (pure file operations)
- Itinerary management may require user confirmation for booking decisions
- Independent invocation: run folder management first, then optionally run itinerary management
- Automated systems can trigger folder management independently

## RUN Re-runnability Checklist

This checklist verifies that RUN execution is properly idempotent, enabling multiple passes through the same journey folder without duplication or unnecessary work. Use this checklist to confirm re-runnability is maintained as the SOP evolves.

### Re-runnability Verification Points

**1. File Saving Operations (Procedure 2)**
- ✓ Before flagging a file for saving, check if file already exists at target location
- ✓ If file exists with correct name, skip saving (no action needed)
- ✓ If file exists with incorrect name, flag for renaming (not re-saving)
- ✓ Multiple RUN executions do not create duplicate files

**2. File Renaming Operations (Procedure 1, Helper Procedure A)**
- ✓ Only files with incorrect names are flagged for renaming
- ✓ Files already correctly named are not renamed again
- ✓ Renaming operations are applied once per file

**3. Email Operations (Procedure 2)**
- ✓ Email searches are filtered by date range to avoid processing unrelated emails
- ✓ Promotional email deletions only occur for past journeys
- ✓ Booking confirmations are retained (never deleted)
- ✓ Email processing does not re-download already-saved attachments

**4. Consistency Across Multiple Runs**
- ✓ Running RUN once produces the same result as running it twice consecutively
- ✓ No error messages about duplicate files or conflicting operations
- ✓ Action lists shrink with each subsequent RUN (as issues are resolved)
- ✓ Final RUN with no new bookings produces minimal or no actions

**5. State Preservation**
- ✓ Previous work is not overwritten or lost
- ✓ Completed tasks remain completed
- ✓ Files do not revert to incorrect naming

### Expected Behaviour Across Multiple RUNs

**First RUN (new journey folder)**:
- Organize all files
- Rename incorrectly named files
- Save all booking confirmations from email
- Action list includes all identified file operations

**Second RUN (after new booking added)**:
- Detect new booking file
- Save corresponding email confirmation (if exists)
- Rename new file if needed
- Action list only includes operations for new booking

**Third RUN (no changes)**:
- No file operations needed (all files correctly organized)
- No email saves needed (all confirmations already saved)
- Action list is empty or minimal

This re-runnable design ensures that each RUN builds on previous work, incorporating new information while preserving completed tasks, enabling the journey folder to evolve naturally as bookings are made, cancelled, or modified.

---

**End of Standard Operating Procedure**
