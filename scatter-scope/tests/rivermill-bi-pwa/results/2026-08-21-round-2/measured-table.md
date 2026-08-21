# Measured table

A type consumers (graph, tests excluded) · D out-degree · B vocabulary spread (grep, whole corpus) · C sites · leak = B minus the A files · score = C x leak/B, the rank that puts a leaking module first with no oracle.

A `note` of "no distinctive vocabulary" is the B floor: the instrument had nothing to grep for. Read it as that, never as well hidden; A carries the low side.

## Modules (384 non-test, ranked by score)

| module | A | D | B | C | leak | score | vocabulary sample | note |
|---|---:|---:|---:|---:|---:|---:|---|---|
| `web/src/pipeline/api.ts` | 16 | 3 | 122 | 1248 | 108 | 1105 | Reply, p_note, r_note, a_note, s_note, Person |  |
| `web/src/lib/auth.ts` | 11 | 2 | 214 | 1129 | 203 | 1071 | auth, AppRun, addedBy, addedAt, AppUser, saveRole |  |
| `spheres/schedule/api/config.js` | 3 | 1 | 199 | 772 | 196 | 760 | config, isPosInt, validateConfig |  |
| `server/shared/auth.js` | 3 | 9 | 154 | 726 | 152 | 717 | auth, newCode, codeStr, startMs, newToken, sendMail |  |
| `spheres/social/ui/api.ts` | 15 | 3 | 85 | 499 | 74 | 434 | Grade, sentAt, tiktok, LastMsg, Message, takenAt |  |
| `spheres/relationships/ui/api.ts` | 3 | 1 | 85 | 446 | 82 | 430 | Match, Party, userId, eventId, claimId, lastname |  |
| `server/shared/datasets.js` | 3 | 0 | 48 | 388 | 45 | 364 | datasets, DATASETS, knownDataset, servedDatasets |  |
| `spheres/schedule/api/providers/sonas.js` | 4 | 0 | 79 | 354 | 78 | 350 | sonas, headcount, VENUE_TZ_SQL, WEDDINGS_SQL, utcSqlString, mapWeddingRow |  |
| `connectors/spar/api/upsert.js` | 1 | 1 | 117 | 310 | 116 | 307 | upsert, pkCount, clipRow, segRows, passStart, valueRows |  |
| `connectors/googlereviews/api/upsert.js` | 2 | 1 | 117 | 302 | 115 | 297 | upsert, dataIds, rawCols, placeSQL, placeRow, ownerCols |  |
| `connectors/awsconnect/api/upsert.js` | 0 | 1 | 118 | 295 | 118 | 295 | upsert, fmtFor, localOf, DAY_NUM, fmtCache, tsToMysql |  |
| `server/shared/runbook.js` | 4 | 0 | 62 | 313 | 58 | 293 | runbook, loadRunbook, jobCodeLower, extractPrompt, resolveRunbook |  |
| `connectors/rezdy/api/upsert.js` | 1 | 1 | 117 | 278 | 116 | 276 | upsert, categoryId, voucherCode, localToMysql, storedLocalText, captureBookingChanges |  |
| `server/shared/testdb.js` | 0 | 1 | 36 | 276 | 36 | 276 | testdb, withTxn |  |
| `connectors/xero/api/upsert.js` | 1 | 1 | 117 | 275 | 116 | 273 | upsert, mysqlDt, LINE_SQL, LINE_COLS, xeroDateMs, TRACKING_SQL |  |
| `spheres/schedule/api/providers/rezdy.js` | 1 | 1 | 73 | 277 | 72 | 273 | rezdy, GRID_SQL, deriveSlots, OCCUPANCY_SQL |  |
| `connectors/deputy/api/upsert.js` | 1 | 1 | 117 | 259 | 116 | 257 | upsert, dateOnly, epochToMysql |  |
| `connectors/clover/api/upsert.js` | 1 | 1 | 117 | 252 | 116 | 250 | upsert, lineMods, sumCents, msToLocal, lineTaxes, lineDiscounts |  |
| `connectors/square/api/upsert.js` | 1 | 1 | 117 | 250 | 116 | 248 | upsert, isoToLocal |  |
| `connectors/sonas/api/upsert.js` | 1 | 2 | 117 | 245 | 116 | 243 | upsert, captureEventChanges |  |
| `spheres/schedule/ui/api.ts` | 7 | 2 | 33 | 221 | 26 | 174 | Entry, moveId, TermRow, Category, postMove, MoveBody |  |
| `spheres/social/ui/perf-derive.ts` | 2 | 1 | 6 | 256 | 4 | 171 | Grain, DayRow, DAY_RE, PerfRow, SortKey, Typical |  |
| `web/src/ui/boardDrag.ts` | 4 | 1 | 17 | 217 | 13 | 166 | onLift, onDrop, fromKey, specFor, canDrag, dropSpec |  |
| `spheres/publicity/ui/api.ts` | 3 | 2 | 56 | 173 | 53 | 164 | Coverage, created_at, addCoverage, coverageCount, CoverageInput, CoverageCount |  |
| `spheres/customer-service/ui/api.ts` | 1 | 0 | 11 | 175 | 10 | 159 | rangOut, CallDay, CallRow, CallRep, agentId, waitSecs |  |
| `server/shared/sync-runs.js` | 26 | 1 | 65 | 259 | 39 | 155 | endRun, syncDue, BEAT_MS, beginRun, syncBusy, elapsedMs |  |
| `spheres/coord/ui/api.ts` | 5 | 2 | 40 | 150 | 35 | 131 | Space, Window, Meeting, sweepNow, LeaderRow, TaskState |  |
| `spheres/reputation/ui/api.ts` | 5 | 1 | 23 | 160 | 18 | 125 | Place, Policy, Review, avgRating, totalScore, localGuide |  |
| `web/src/ui/FilterBar.tsx` | 2 | 2 | 18 | 138 | 16 | 123 | onAll, onNone, FilterBar, optionsOf, FilterCheck, FacetButton |  |
| `server/shared/ready.js` | 1 | 1 | 20 | 124 | 19 | 118 | freshIds, staleIds, readyWork, workQueue, makeReader, describeWork |  |
| `server/shared/grants.js` | 3 | 1 | 6 | 141 | 5 | 118 | needVerb, VERB_ORDER, DATA_TOKEN, parseGrants, formatToken, warnedTokens |  |
| `web/src/ui/atoms.tsx` | 44 | 0 | 44 | 227 | 22 | 114 | Stars, Avatar, PillTone, AvatarSize, CountBadge, StatusPill |  |
| `spheres/projects/ui/api.ts` | 2 | 3 | 12 | 136 | 10 | 113 | setBall, notedAt, Verdict, locator, LivesAt, stageAt |  |
| `scripts/import-meta-exports.mjs` | 0 | 4 | 23 | 103 | 23 | 103 | winKey, mdyToIso, permalink, fileLabel, ownHandles, detectType |  |
| `connectors/instagram/api/shortcode.js` | 3 | 0 | 14 | 131 | 11 | 103 | shortcode, IG_ALPHABET, pkToShortcode, shortcodeToPk, shortcodeFromPermalink |  |
| `web/src/lib/format.ts` | 28 | 0 | 34 | 288 | 12 | 102 | prefs, fmtParts, DateOrder, weekStart, fmtNumber, fmtRegion |  |
| `scripts/refresh-meta-recent.mjs` | 0 | 4 | 21 | 101 | 21 | 101 | skillRef, runSkill, faultText, IG_HANDLES, overseerUp, resolveOwnPk |  |
| `connectors/instagram/api/insights-sync.js` | 1 | 2 | 28 | 102 | 27 | 98 | dayUtc, ownerPk, pollSet, mediaPk, fullWalk, dayBounds |  |
| `server/shared/spar-pipeline.js` | 5 | 4 | 39 | 105 | 34 | 92 | claimSql, loadClaims, LAST_TOUCH, MEMBER_SQL, memberJson, configPath |  |
| `web/src/lib/error-codes.ts` | 9 | 0 | 31 | 125 | 22 | 89 | errorText, ErrorCode, error-codes, DISJUNCTIVE, localizeParams |  |
| `spheres/social/ui/Rolodex.tsx` | 3 | 11 | 15 | 108 | 12 | 86 | NO_STAR, onSweep, Grouping, isSoured, gridIcon, listIcon |  |
| `web/src/ui/CtxMenu.tsx` | 6 | 0 | 41 | 96 | 35 | 82 | CtxSub, CtxItem, CtxMenu, viewport, CtxButton, subOffsets |  |
| `web/src/lib/journey.ts` | 11 | 1 | 17 | 110 | 12 | 78 | loadSeq, sphereOf, loadTail, saveTail, JOURNEY_CAP, JourneyVerb |  |
| `connectors/facebook/api/insights-sync.js` | 3 | 1 | 28 | 84 | 25 | 75 | postPk, graphId, endTime, pageIdOf, upsertPost, statusType |  |
| `spheres/financial/ui/vocab.ts` | 2 | 1 | 27 | 79 | 25 | 73 | vocab, LocalName, localNameIn, VOCAB_ROUTE, useLocalName, SOURCE_LOCALE |  |
| `server/shared/stage-advance.js` | 5 | 6 | 31 | 85 | 26 | 71 | sqlDate, FLIP_UTC, frameLook, envPrefix, STAGE_GUARD, stage-advance |  |
| `server/shared/connector-tenant.js` | 21 | 1 | 41 | 144 | 20 | 70 | tenantOf, connector-tenant |  |
| `web/src/lib/use-api-view.ts` | 38 | 3 | 53 | 239 | 15 | 68 | paramsOf, apiViewKey, useApiView, apiViewPath, keepPrevious, ApiViewRoute |  |
| `spheres/social/api/instance.js` | 0 | 3 | 20 | 66 | 20 | 66 | loadVocab, stagePassDue |  |
| `server/shared/job-runs.js` | 6 | 1 | 26 | 84 | 20 | 65 | runBase, job-runs, runBPersist, normalizeResolvedVersion |  |
| `spheres/social/api/stage-advance.js` | 3 | 4 | 31 | 70 | 28 | 63 | PK_OF, entryPass, CAMPAIGN_OF, entryPassDue, stage-advance, HAS_NEW_OUTBOUND |  |
| `spheres/library/ui/api.ts` | 5 | 0 | 26 | 69 | 23 | 61 | Source, HitKind, SourceId, sourceOf, SearchKind, ItemResponse |  |
| `scripts/import-otter-corpus.mjs` | 0 | 3 | 5 | 61 | 5 | 61 | fmDoc, fmText, mdBody, asArray, inLedger, stemDate |  |
| `web/src/ui/Overlay.tsx` | 11 | 1 | 27 | 102 | 16 | 60 | Overlay, panelClassName |  |
| `agent/error-codes.js` | 2 | 0 | 31 | 63 | 29 | 59 | error-codes |  |
| `spheres/financial/ui/export.ts` | 1 | 1 | 8 | 67 | 7 | 59 | setOff, NUM_FMT, viewWord, viewLabel, sheetName, localName |  |
| `web/src/ui/Board.tsx` | 7 | 4 | 20 | 86 | 13 | 56 | Strip, DragCard, DropZone, DragBoard, snapIndex, boardClass |  |
| `connectors/instagram/api/jobs.js` | 3 | 2 | 11 | 61 | 10 | 55 | longId, shortPk, viewerId, DUMP_SQL, handlesOf, normCount |  |
| `spheres/projects/api/derive.js` | 1 | 0 | 5 | 68 | 4 | 54 | statusOf, prereqId, statusAt, prereqsOf, wouldCycle, dependentId |  |
| `server/shared/credentials.js` | 24 | 4 | 38 | 145 | 14 | 53 | fieldOf, readToken, updatedBy, writeToken, setCredential, clearCredential |  |
| `web/src/ui/DeepLink.tsx` | 8 | 1 | 29 | 73 | 21 | 53 | DeepLink |  |
| `server/shared/error-codes.js` | 5 | 0 | 31 | 62 | 26 | 52 | error-codes |  |
| `web/src/lib/view-registry.ts` | 8 | 1 | 17 | 99 | 9 | 52 | nextId, Assertion, ChoiceSet, anchorElement, view-registry, currentAnchors |  |
| `connectors/linkedin/api/jobs.js` | 1 | 2 | 5 | 52 | 5 | 52 | isSelf, ownerUrn, profileUrn, connectedAt, connectedUrn, validateInbox |  |
| `web/src/ui/ReachNote.tsx` | 30 | 3 | 43 | 169 | 13 | 51 | useReach, ReachNote |  |
| `spheres/publicity/api/stage-advance.js` | 3 | 4 | 31 | 56 | 28 | 51 | stage-advance |  |
| `server/shared/pipeline-fixture.js` | 2 | 1 | 18 | 57 | 16 | 51 | viewBody, VIEW_BODY, platformSql, tempTableDdl, statementFrom, pipeline-fixture |  |
| `agent/tools.js` | 1 | 1 | 8 | 58 | 7 | 51 | BI_BASE, rowFault, toolNames, toolEntries, deriveTools, fetchEntries |  |
| `connectors/xero/api/xero-client.js` | 2 | 1 | 17 | 56 | 15 | 49 | accessToken, extractList, xero-client, PRODUCT_BASES, makeXeroClient, CONNECTIONS_URL |  |
| `connectors/tiktok/api/insights-sync.js` | 1 | 2 | 25 | 49 | 24 | 47 | openId, videoRow, unixSeconds, unixToVenue, upsertVideo, loadTokenFile |  |
| `web/src/app/AuthGate.tsx` | 6 | 6 | 19 | 69 | 13 | 47 | AuthCtx, AuthGate, onSignedIn, LoginScreen, AuthUpdateCtx, applyStoredPrefs |  |
| `web/src/lib/url-state.ts` | 20 | 3 | 30 | 132 | 10 | 44 | readRaw, url-state, writeParam, useUrlParam, useStringParam |  |
| `web/src/ui/SectionHeader.tsx` | 19 | 2 | 35 | 95 | 16 | 43 | SectionHeader |  |
| `web/src/lib/interaction-context.ts` | 2 | 4 | 11 | 53 | 9 | 43 | byteSize, buildView, EMPTY_EXTRAS, JOURNEY_TAIL, ContextExtras, choiceFilters |  |
| `server/shared/tenancy.js` | 6 | 1 | 16 | 61 | 11 | 42 | warnMissing, groupTenants, tenantContext, creationTenant, FOUNDING_TENANT |  |
| `spheres/financial/ui/fy.ts` | 1 | 2 | 3 | 63 | 2 | 42 | FYRow, fyYear, fyRows, fyLabel, fyWindow, yearLabel |  |
| `server/shared/db.js` | 44 | 0 | 38 | 104 | 15 | 41 | loadEnv, withWrite, savepointSeq |  |
| `web/src/lib/slot-store.ts` | 7 | 0 | 11 | 114 | 4 | 41 | SlotView, wakeView, clearSlot, wakeParam, slot-store, setSlotPath |  |
| `web/src/lib/api.ts` | 34 | 1 | 32 | 142 | 9 | 40 | apiGet, apiPost, ApiError, refusalOf |  |
| `web/src/ui/ParamChips.tsx` | 9 | 4 | 18 | 79 | 9 | 40 | allLabel, ParamChips, ChipOption |  |
| `connectors/onedrive/api/graph-client.js` | 3 | 2 | 9 | 60 | 6 | 40 | pathOf, searchUrl, postGrant, GRAPH_BASE, driveOwner, filterKind |  |
| `spheres/financial/ui/matrix.ts` | 2 | 1 | 7 | 55 | 5 | 39 | perfNet, DisplayRow, MonthMatrix, modifierNet, monthMatrix, showModifier |  |
| `spheres/projects/ui/views/Gantt.tsx` | 1 | 9 | 17 | 40 | 16 | 38 | Gantt, chainOf, onWrite, MsPanel, Derived, todayUTC |  |
| `server/shared/job-claims.js` | 2 | 0 | 12 | 46 | 10 | 38 | ttlMinutes, job-claims, intervalMinutes, sweepExpiredClaims |  |
| `connectors/sonas/api/sonas-client.js` | 3 | 0 | 6 | 56 | 4 | 37 | WS_URL, ejsonDate, sonas-client, ejsonToMysql, EPOCH_2100_MS, EPOCH_1900_MS |  |
| `spheres/schedule/ui/week.ts` | 3 | 1 | 5 | 61 | 3 | 37 | DayCell, isToday, todayIso, mondayOf, weekCells, weekRange |  |
| `web/src/ui/FreshnessNote.tsx` | 11 | 1 | 25 | 65 | 14 | 36 | FreshnessNote |  |
| `connectors/awsconnect/api/sigv4.js` | 2 | 0 | 8 | 47 | 6 | 35 | sigv4, rfc3986, amzDate, sha256hex, datestamp, signingKey |  |
| `spheres/coord/api/decode.js` | 1 | 0 | 2 | 70 | 1 | 35 | lastAtName, decodeTask, messageName, lifecycleOf, ASSIGN_VERBS, spaceOfMessage |  |
| `spheres/publicity/api/pipeline-fixture.js` | 0 | 2 | 18 | 34 | 18 | 34 | pipeline-fixture |  |
| `spheres/social/api/pipeline-fixture.js` | 0 | 2 | 18 | 34 | 18 | 34 | pipeline-fixture |  |
| `spheres/coord/api/meetings.js` | 1 | 1 | 3 | 51 | 2 | 34 | getMeeting, clampLimit, likeFragment, getTranscript, addressMeeting, searchMeetings |  |
| `web/src/lib/tool-labels.ts` | 1 | 0 | 8 | 38 | 7 | 33 | FALLBACK, tool-labels, activityLine, LABELLED_TOOLS |  |
| `spheres/relationships/api/identity.js` | 1 | 0 | 2 | 66 | 1 | 33 | personId, igHandle, normName, sparKeys, sonasKeys, normEmail |  |
| `web/src/ui/PersonRow.tsx` | 3 | 1 | 13 | 41 | 10 | 32 | PersonRow |  |
| `spheres/schedule/api/reconcile-logic.js` | 2 | 0 | 4 | 64 | 2 | 32 | agedOut, targetOf, matchesTarget, parseNativeId, decidePending, listOpenMoves |  |
| `connectors/facebook/insights-sync.js` | 0 | 6 | 24 | 31 | 24 | 31 | insights-sync |  |
| `connectors/instagram/insights-sync.js` | 0 | 7 | 24 | 31 | 24 | 31 | insights-sync |  |
| `connectors/tiktok/insights-sync.js` | 0 | 7 | 24 | 31 | 24 | 31 | TOKEN_FILE, insights-sync |  |
| `web/src/lib/breakpoint.ts` | 3 | 0 | 16 | 38 | 13 | 31 | useDesktop, breakpoint, DESKTOP_QUERY, DESKTOP_MIN_PX, subscribeDesktop |  |
| `server/shared/click-log.js` | 1 | 0 | 16 | 33 | 15 | 31 | click-log, recordClick |  |
| `spheres/social/ui/CampaignPipeline.tsx` | 2 | 3 | 7 | 44 | 5 | 31 | onNew, onPeople, selectedId, deleteAction, CampaignList, CampaignPipeline |  |
| `web/src/app/sphere.ts` | 18 | 0 | 31 | 67 | 14 | 30 | Sphere, NavItem |  |
| `web/src/app/App.tsx` | 1 | 14 | 12 | 30 | 12 | 30 | Shell, resetKey, Doorbell, accessIcon, NoSuchPage, queryClient |  |
| `connectors/awsconnect/api/sync.js` | 13 | 0 | 11 | 30 | 11 | 30 | listKey, venueTz, listAll, windowMs, syncCost, syncUsers |  |
| `spheres/schedule/api/almanac.js` | 2 | 2 | 3 | 45 | 2 | 30 | termRow, optText, optDate, MONTH_RE, FILE_SQL, entryRow |  |
| `spheres/publicity/api/stage-pass.js` | 0 | 2 | 16 | 29 | 16 | 29 | stage-pass |  |
| `spheres/social/api/stage-pass.js` | 0 | 2 | 16 | 29 | 16 | 29 | stage-pass |  |
| `web/src/pipeline/CampaignBoard.tsx` | 1 | 7 | 9 | 33 | 8 | 29 | boardColumns, strayColumns, CampaignBoard, offFunnelColumns |  |
| `server/shared/connector-health.js` | 1 | 1 | 8 | 33 | 7 | 29 | RUN_STRIP, recentRuns, healthRows, HEALTH_KINDS, HEALTH_REASONS, connector-health |  |
| `spheres/coord/api/read.js` | 2 | 3 | 8 | 29 | 8 | 29 | IN_SCOPE, listTasks, SCOPE_JOIN, syncStatus, taskSource, listSpaces |  |
| `spheres/financial/ui/views/Labour.tsx` | 1 | 15 | 14 | 30 | 13 | 28 | Labour, pctLabel, deltaLabel, hoursLabel, hoursOrDash, moneyOrDash |  |
| `spheres/coord/prelink.js` | 0 | 3 | 9 | 28 | 9 | 28 | prelink, prelinkMeetings |  |
| `spheres/library/api/hits.js` | 2 | 0 | 3 | 41 | 2 | 27 | Q_MAX, HIT_KINDS, isNotFound, PAGE_LIMIT, SEARCH_KINDS, EMPTY_SEARCH |  |
| `spheres/coord/api/instance.js` | 0 | 3 | 11 | 26 | 11 | 26 | prelink, prelinkDue, reconstructDue |  |
| `server/shared/closure.js` | 1 | 0 | 3 | 39 | 2 | 26 | rowFor, libRefs, storeDir, notFound, findTypeB, artifactRef |  |
| `connectors/linkedin/api/memdb.js` | 0 | 0 | 15 | 25 | 15 | 25 | memdb, rowKey |  |
| `web/src/app/ChatPane.tsx` | 1 | 2 | 11 | 28 | 10 | 25 | ChatPane, ChatUnreachable |  |
| `server/shared/walls.js` | 4 | 1 | 9 | 45 | 5 | 25 | pairKey, WAGES_WALL, wallContext, missingTables, warnedNoWalls, WAGES_SOURCE_TYPES |  |
| `connectors/otter/api/memdb.js` | 0 | 0 | 15 | 24 | 15 | 24 | memdb, COALESCE_COLS |  |
| `spheres/financial/ui/period.ts` | 5 | 2 | 8 | 63 | 3 | 24 | Preset, fyStart, monthsOf, extendTo, monthLabel, shortMonth |  |
| `server/shared/anthropic.js` | 2 | 2 | 13 | 27 | 11 | 23 | MODEL_IDS, anthropic, runRunbook |  |
| `web/src/ui/FilterRow.tsx` | 3 | 0 | 12 | 31 | 9 | 23 | FilterRow |  |
| `web/src/pipeline/ContactPanel.tsx` | 3 | 7 | 10 | 33 | 7 | 23 | Event, eventDate, NoteEditor, afterWrite, memberStage, ContactPanel |  |
| `spheres/social/ui/ContactDetail.tsx` | 1 | 9 | 10 | 26 | 9 | 23 | onPick, PostRow, onJoined, shortTime, onRemoved, EntryProse |  |
| `web/src/ui/SelectableCard.tsx` | 3 | 0 | 9 | 34 | 6 | 23 | openLabel, SelectableCard |  |
| `agent/drive-tools.js` | 1 | 0 | 8 | 26 | 7 | 23 | driveSeq, driveTool, driveTools, DRIVE_CODES, drive-tools, resolveDrive |  |
| `spheres/financial/ui/labour-matrix.ts` | 1 | 1 | 2 | 46 | 1 | 23 | round1, wagePct, unitIds, perUnit, unitNames, LabourDay |  |
| `server/shared/hash.js` | 2 | 0 | 13 | 26 | 11 | 22 | sha256 |  |
| `server/shared/venue-date.js` | 6 | 0 | 10 | 54 | 4 | 22 | fmtDay, venueDate, venue-date, epochSeconds |  |
| `server/shared/ollama.js` | 2 | 1 | 10 | 27 | 8 | 22 | ollama, runRunbookLocal |  |
| `web/src/ui/Chips.tsx` | 3 | 1 | 9 | 33 | 6 | 22 | ChipRow |  |
| `connectors/rezdy/api/rezdy-client.js` | 1 | 1 | 6 | 26 | 5 | 22 | payloadOf, rezdy-client, makeRezdyClient |  |
| `spheres/schedule/api/moves.js` | 1 | 5 | 4 | 30 | 3 | 22 | OPEN_SQL, CANCEL_SQL, cancelMove, INSERT_SQL, requestMove, RESOLVE_SQL |  |
| `connectors/spar/api/parse.js` | 1 | 0 | 2 | 45 | 1 | 22 | dateN, tsvText, asGiven, fileStem, needsFix, indentOf |  |
| `web/src/lib/clicklog.ts` | 6 | 2 | 11 | 44 | 5 | 20 | clicklog, logDeepLink, openDeepLink |  |
| `spheres/social/ui/CampaignBoard.tsx` | 1 | 16 | 9 | 23 | 8 | 20 | onReview, DraftChip, MemberCard, CampaignBoard |  |
| `server/shared/contract.js` | 1 | 0 | 2 | 40 | 1 | 20 | isFunc, isString, jobProblems, validateOwnerConfig, reservedNameProblem, RESERVED_SHELL_NAMES |  |
| `connectors/tiktok/api/auth-bootstrap.js` | 0 | 3 | 15 | 19 | 15 | 19 | auth-bootstrap |  |
| `connectors/xero/api/auth-bootstrap.js` | 0 | 3 | 15 | 19 | 15 | 19 | auth-bootstrap |  |
| `spheres/financial/ui/api.ts` | 9 | 2 | 10 | 47 | 4 | 19 | PLRow, exGst, PLSource, prevExGst, LabourRow, ProductRow |  |
| `spheres/coord/api/jobs-a.js` | 1 | 3 | 9 | 20 | 8 | 18 | jobs-a, entityRows, buildMeetingJobs |  |
| `spheres/schedule/api/providers/local.js` | 4 | 0 | 5 | 30 | 3 | 18 | toMin, getEntry, shiftEnd, MOVE_SQL |  |
| `spheres/coord/ui/views/Meetings.tsx` | 1 | 10 | 3 | 18 | 3 | 18 | setAfter, setPages, monthKey, Transcript, PERSON_CHIPS, groupByMonth |  |
| `spheres/financial/api/read.js` | 1 | 7 | 3 | 18 | 3 | 18 | putCell, SEG_CAT, rentRow, sectionOf, rezdyRows, sonasRows |  |
| `spheres/social/api/performance.js` | 1 | 1 | 3 | 27 | 2 | 18 | igType, fbType, ownPks, fbPosts, monthOf, ttPosts |  |
| `connectors/otter/api/jobs.js` | 2 | 2 | 1 | 18 | 1 | 18 | ACCOUNT_ID, validateList, UPSERT_CHUNK, recordingRow, validateFetch, UPSERT_RECORDINGS_SQL |  |
| `web/src/ui/GroupedList.tsx` | 3 | 1 | 10 | 24 | 7 | 17 | renderBody, GroupedList |  |
| `web/src/app/ChatAssistant.tsx` | 0 | 12 | 9 | 17 | 9 | 17 | ToolLine, UserText, DOCK_KEY, dockIcon, floatIcon, PanelMode |  |
| `spheres/social/ui/cards.tsx` | 4 | 6 | 8 | 34 | 4 | 17 | onFunnel, inCampaign, openMenuItems, campaignNames |  |
| `server/shared/manifest.js` | 2 | 0 | 6 | 26 | 4 | 17 | skillsRoot, loadManifest, manifestPaths, REQUIRED_KEYS, validateManifest, scanManifestPaths |  |
| `spheres/schedule/ui/ConfirmMove.tsx` | 1 | 3 | 4 | 23 | 3 | 17 | onConfirm, ConfirmMove |  |
| `spheres/social/ui/PerformanceSection.tsx` | 1 | 12 | 12 | 17 | 11 | 16 | Scope, SortTh, onSort, labelOf, DeltaChip, FIRST_SLICE |  |
| `server/shared/stage-vocabulary.js` | 4 | 0 | 9 | 29 | 5 | 16 | subsetAllows, stage-vocabulary, buildStageVocabulary |  |
| `web/src/lib/locale.ts` | 3 | 2 | 6 | 32 | 3 | 16 | regionIn, formatLocale, activateLocale, ES_419_REGIONS, ZH_HANT_REGIONS, ZH_HANS_REGIONS |  |
| `server/shared/credential-manifests.js` | 2 | 0 | 5 | 27 | 3 | 16 | manifestFor, DEFAULT_ROOT, listManifests, credential-manifests |  |
| `server/shared/trail.js` | 2 | 0 | 5 | 27 | 3 | 16 | recordWrite |  |
| `server/shared/sql-static.js` | 3 | 0 | 5 | 41 | 2 | 16 | IDENT, sqlRaw, cleanIdent, sql-static, matchParen, parseWrites |  |
| `web/src/ui/HoverTip.tsx` | 1 | 0 | 7 | 16 | 6 | 14 | HoverTip |  |
| `server/shared/contract-helpers.js` | 4 | 0 | 5 | 68 | 1 | 14 | faultReason, callerMetaUrl, contractReason, compileContract, contract-helpers |  |
| `spheres/library/ui/SearchBar.tsx` | 2 | 7 | 4 | 27 | 2 | 14 | setText, SearchBar, SETTLE_MS, useAnyReach, useQueryParam, useSelectedSources |  |
| `spheres/reputation/ui/lanes.ts` | 1 | 1 | 2 | 28 | 1 | 14 | Lanes, LaneKpi, overTarget, deriveLanes, responseDays, negativeFirst |  |
| `connectors/googlereviews/api/import-historical.js` | 1 | 1 | 8 | 15 | 7 | 13 | runImport, import-historical |  |
| `web/src/lib/grants.ts` | 6 | 0 | 7 | 47 | 2 | 13 | GrantVerb, AuthReach, GrantToken |  |
| `spheres/financial/ui/views/ProfitAndLoss.tsx` | 1 | 19 | 7 | 15 | 6 | 13 | NetRow, parseSrc, segCount, dashBelow, Statement, monthNets |  |
| `web/src/app/chat-handle.tsx` | 2 | 1 | 5 | 21 | 3 | 13 | ChatHandle, chat-handle |  |
| `web/src/pipeline/StagesEditor.tsx` | 2 | 4 | 5 | 22 | 3 | 13 | onRemove, StageRow, StagesEditor |  |
| `web/src/ui/useCardSelection.ts` | 3 | 1 | 9 | 18 | 6 | 12 | groupFor, ClickLike, CardGestures, CardSelection, useCardSelection |  |
| `connectors/deputy/api/deputy-client.js` | 1 | 1 | 5 | 15 | 4 | 12 | deputy-client, makeDeputyClient |  |
| `spheres/schedule/ui/views/Pending.tsx` | 1 | 7 | 4 | 12 | 4 | 12 | MoveRow, canWrite |  |
| `connectors/googlereviews/api/serpapi-client.js` | 1 | 1 | 4 | 16 | 3 | 12 | SEARCH_URL, serpapi-client, makeSerpapiClient |  |
| `connectors/googlereviews/import-historical.js` | 0 | 4 | 8 | 11 | 8 | 11 | import-historical |  |
| `spheres/library/ui/Results.tsx` | 3 | 6 | 7 | 19 | 4 | 11 | Cursor, fmtSize, MediaGrid, KindGlyph, kindLabel, reachLabel |  |
| `spheres/coord/ui/views/MeetingFollowUp.tsx` | 1 | 5 | 3 | 17 | 2 | 11 | meetingPath, spaceRoomUrl, MeetingFollowUp, composeFollowUp |  |
| `server/shared/chat.js` | 1 | 3 | 3 | 17 | 2 | 11 | handleChat, toolRoutes |  |
| `server/shared/secret-box.js` | 2 | 0 | 8 | 14 | 6 | 10 | IV_LEN, TAG_LEN, plaintext, secret-box |  |
| `connectors/dropbox/api/dropbox-client.js` | 3 | 2 | 6 | 20 | 3 | 10 | homeLink, EXT_KIND, HOME_URL, API_BASE, matchMeta, TAGS_BATCH |  |
| `spheres/social/ui/PeopleSection.tsx` | 1 | 12 | 4 | 13 | 3 | 10 | parseOff, pkFromPath, parseQuery, desktopLike, STARS_CODEC, parseCollab |  |
| `connectors/clover/api/clover-client.js` | 1 | 1 | 4 | 14 | 3 | 10 | elementsOf, clover-client, makeCloverClient |  |
| `spheres/projects/api/read.js` | 1 | 7 | 3 | 10 | 3 | 10 | slugOk, livesAt, badSlug, postLink, noProject, projectId |  |
| `spheres/financial/ui/window.ts` | 1 | 1 | 2 | 20 | 1 | 10 | filterRows, OptionalSource, OPTIONAL_SOURCES |  |
| `connectors/deputy/api/sync.js` | 1 | 0 | 2 | 10 | 2 | 10 | maxId, maxMs, floorSec, sinceText, syncIncremental |  |
| `spheres/coord/api/jobs.js` | 1 | 2 | 2 | 20 | 1 | 10 | threadKey, replayLifecycle, LIFECYCLE_STATUS, reconstructTasks |  |
| `web/src/lib/use-pathname.ts` | 6 | 2 | 9 | 26 | 3 | 9 | usePathname, use-pathname |  |
| `connectors/facebook/api/graph-client.js` | 1 | 1 | 9 | 10 | 8 | 9 | POST_FIELDS, graph-client |  |
| `connectors/instagram/api/graph-client.js` | 1 | 1 | 9 | 10 | 8 | 9 | graph-client |  |
| `agent/system-prompt.js` | 1 | 0 | 9 | 10 | 8 | 9 | system-prompt |  |
| `spheres/social/api/read.js` | 1 | 7 | 5 | 9 | 5 | 9 | ownPk, draftRow, isMember, actorFor, draftJson, unreadFor |  |
| `connectors/github/api/github-client.js` | 1 | 1 | 4 | 12 | 3 | 9 | encodePath, USER_AGENT, resetWaitMs, API_VERSION, github-client, isRateLimited |  |
| `server/shared/model-api.js` | 1 | 2 | 4 | 12 | 3 | 9 | model-api, runRunbookApi |  |
| `spheres/library/api/read.js` | 1 | 4 | 1 | 9 | 1 | 9 | itemRoute, defaultLog, searchRoute, buildHandleApi |  |
| `spheres/schedule/reconcile.js` | 0 | 7 | 1 | 9 | 1 | 9 | STALE_SQL, CLOSE_SQL, reconcilePass |  |
| `spheres/schedule/ui/views/Almanac.tsx` | 1 | 9 | 8 | 8 | 8 | 8 | Month, dayOf, Legend, termTag, windowOf, CAT_WORD |  |
| `web/src/lib/org-identity.ts` | 3 | 1 | 5 | 14 | 3 | 8 | TaxRegister, org-identity, TAX_REGISTERS, taxRegisterFor, LetterheadLines, OrgIdentityFields |  |
| `server/app.js` | 0 | 16 | 5 | 8 | 5 | 8 | _mods, readGate, adminOnly, relToRepo, checkAuth, DEPLOY_LOG |  |
| `web/src/lib/assistant-runtime.ts` | 1 | 7 | 4 | 11 | 3 | 8 | Frame, ackedSeq, onChatId, frameQueue, lastUserText, restoreChatId |  |
| `spheres/publicity/ui/CoverageSection.tsx` | 2 | 3 | 4 | 17 | 2 | 8 | onAdded, coverageBadge, coverageSection, CoverageSection |  |
| `web/src/lib/chat-store.ts` | 1 | 0 | 3 | 12 | 2 | 8 | headId, isRecord, setChatId, saveRecord, chatThread, loadRecord |  |
| `spheres/customer-service/api/transcripts.js` | 1 | 3 | 2 | 15 | 1 | 8 | transcribeCall, readTranscript |  |
| `spheres/schedule/api/read.js` | 1 | 10 | 2 | 8 | 2 | 8 | metaRoute, ghostEntry, slotsRoute, rangeRoute, upsertEntry, pendingRoute |  |
| `server/shared/versions.js` | 1 | 0 | 2 | 15 | 1 | 8 | latestRow, commitSha, decideAppend |  |
| `server/shared/access.js` | 1 | 2 | 1 | 8 | 1 | 8 | routeOf, emptyAnswer, missingRefs |  |
| `connectors/awsconnect/api/aws-client.js` | 1 | 2 | 4 | 9 | 3 | 7 | aws-client, makeAwsClient |  |
| `spheres/reputation/ui/ReviewCard.tsx` | 2 | 5 | 3 | 22 | 1 | 7 | isLong, ClampText, showPlace, reviewsUrl, ReviewCard, CLAMP_CHARS |  |
| `spheres/social/ui/CampaignDelete.tsx` | 2 | 3 | 3 | 21 | 1 | 7 | onDeleted, CampaignDelete, CampaignDeleteButton |  |
| `web/src/lib/drive.ts` | 1 | 8 | 2 | 14 | 1 | 7 | slotOf, DriveView, driveSplit, DriveEvent, slotAddress, driveSelect |  |
| `web/src/lib/view-scope.ts` | 11 | 0 | 13 | 40 | 2 | 6 | useSlot, ViewScope, view-scope |  |
| `web/src/app/PrefsPanel.tsx` | 1 | 6 | 5 | 8 | 4 | 6 | ENDONYM, PrefsPanel, DATE_SAMPLE |  |
| `connectors/googlechat/api/chat-client.js` | 1 | 1 | 5 | 7 | 4 | 6 | chat-client, makeChatClient |  |
| `spheres/coord/capture.js` | 2 | 0 | 4 | 12 | 2 | 6 | doneSignal, CAPTURE_REPO, OTHER_BUSINESS_PREFIX |  |
| `spheres/publicity/api/jobs.js` | 1 | 3 | 4 | 8 | 3 | 6 | memberFromId, buildPublicityJobs |  |
| `scripts/deploy-skills.mjs` | 0 | 3 | 4 | 6 | 4 | 6 | arefs, isSkillRef, deploy-skills |  |
| `connectors/googlereviews/api/sync.js` | 1 | 1 | 3 | 6 | 3 | 6 | isoDate, markRun, reviewId, syncPlace, loadPlaces, searchesLast30d |  |
| `server/shared/deepseek.js` | 2 | 2 | 3 | 18 | 1 | 6 | deepseek, MODEL_ID, runRunbookDeepseek |  |
| `spheres/customer-service/api/calls.js` | 1 | 2 | 2 | 12 | 1 | 6 | costOf, heatOf, repsOf, daysOf, addDays, callsOf |  |
| `spheres/customer-service/api/read.js` | 1 | 5 | 1 | 6 | 1 | 6 | DAYS_MAX, CAL_DATE, callsParams |  |
| `server/shared/events.js` | 1 | 0 | 1 | 6 | 1 | 6 | createDoorbell |  |
| `web/src/app/match.ts` | 6 | 1 | 6 | 29 | 1 | 5 | atAppRoot, activeNav, activeSphere |  |
| `scripts/stage-flip-harness.mjs` | 0 | 5 | 5 | 5 | 5 | 5 | DEEPSEEK, stage-flip-harness |  |
| `spheres/relationships/ui/views/Matches.tsx` | 1 | 6 | 4 | 5 | 4 | 5 | memberId, QueueRow, buildRows, RowMember, sourceLabel, SOURCE_LABELS |  |
| `web/src/app/access-sections.ts` | 2 | 1 | 3 | 15 | 1 | 5 | AccessSection, accessSection, ACCESS_SECTIONS, access-sections, accessSectionFor, accessSectionsFor |  |
| `web/src/lib/chat-starters.ts` | 1 | 0 | 3 | 8 | 2 | 5 | BY_SPHERE, chat-starters, STARTER_SPHERES |  |
| `server/shared/http-json.js` | 1 | 1 | 3 | 8 | 2 | 5 | http-json |  |
| `spheres/schedule/ui/slots.tsx` | 1 | 2 | 2 | 10 | 1 | 5 | slotZones |  |
| `connectors/googlechat/api/sync.js` | 1 | 1 | 1 | 5 | 1 | 5 | nowIso, floorIso, syncSpace, dumpSpaces, persistPage, upsertSpaces |  |
| `spheres/publicity/api/read.js` | 1 | 3 | 1 | 5 | 1 | 5 | buildApi, coverageList, coverageCounts |  |
| `server/shared/http-raw.js` | 18 | 0 | 20 | 35 | 2 | 4 | http-raw |  |
| `web/src/lib/navigate.ts` | 8 | 3 | 4 | 8 | 2 | 4 | closeSecondary |  |
| `spheres/financial/ui/PeriodPicker.tsx` | 3 | 2 | 4 | 14 | 1 | 4 | atDefault, PeriodPicker |  |
| `web/src/lib/chat.ts` | 2 | 4 | 3 | 12 | 1 | 4 | onTool, onError, onDrive, sendChat, ChatSend, ChatProbe |  |
| `connectors/awsconnect/api/presign.js` | 2 | 1 | 3 | 12 | 1 | 4 | presign, presignS3Get |  |
| `web/src/ui/highlight.ts` | 1 | 3 | 2 | 7 | 1 | 4 | highlightAnchor |  |
| `web/src/app/AccessApps.tsx` | 1 | 4 | 2 | 8 | 1 | 4 | FieldRow, RunBlock, SessionRow, AccessApps, reasonText, PRODUCT_NAME |  |
| `spheres/reputation/ui/views/AllReviews.tsx` | 1 | 7 | 2 | 8 | 1 | 4 | AllReviews |  |
| `spheres/schedule/ui/EntryEditor.tsx` | 1 | 2 | 2 | 9 | 1 | 4 | EntryEditor |  |
| `spheres/customer-service/api/policy.js` | 1 | 0 | 1 | 4 | 1 | 4 | loadPolicy |  |
| `web/src/lib/useDoorbell.ts` | 1 | 0 | 3 | 5 | 2 | 3 | useDoorbell |  |
| `web/src/app/AccessRoles.tsx` | 1 | 4 | 3 | 5 | 2 | 3 | onSet, SegRow, CellTone, CellPair, roleCell, RoleDrawer |  |
| `spheres/coord/ui/views/ByPerson.tsx` | 2 | 10 | 3 | 8 | 1 | 3 | ByPerson, TaskSource, PersonTasks |  |
| `spheres/social/api/jobs.js` | 1 | 4 | 3 | 4 | 2 | 3 | GATE_BATCH, CLEAN_HEALTH, buildCrmJobs, anyMarketing, truncateLines, threadMembers |  |
| `web/src/lib/gesture-state.ts` | 1 | 1 | 2 | 6 | 1 | 3 | gesture-state, useGestureState |  |
| `web/src/lib/download.ts` | 1 | 0 | 2 | 6 | 1 | 3 | saveBlob |  |
| `connectors/square/api/square-client.js` | 1 | 1 | 2 | 6 | 1 | 3 | square-client, SQUARE_VERSION, makeSquareClient |  |
| `server/shared/party.js` | 1 | 3 | 2 | 3 | 2 | 3 | claimKey, postClaim, postRetire, liveClaims, jsonEmails, listParties |  |
| `connectors/tiktok/api/tiktok-client.js` | 3 | 1 | 4 | 9 | 1 | 2 | API_HOST, AUTH_HOST, tokenCall, USER_FIELDS, VIDEO_FIELDS, tiktok-client |  |
| `web/src/lib/overseer.ts` | 2 | 1 | 3 | 5 | 1 | 2 | probeOverseer, overseerSecret |  |
| `web/src/pipeline/Roster.tsx` | 3 | 10 | 3 | 3 | 2 | 2 | isDue, rowBadges |  |
| `web/src/app/AccessPeople.tsx` | 1 | 4 | 2 | 4 | 1 | 2 | InviteRow, AccessPeople, effectiveAccess |  |
| `web/src/app/AccessWalls.tsx` | 1 | 3 | 2 | 4 | 1 | 2 | WallCard, AccessWalls |  |
| `web/src/ui/SearchInput.tsx` | 1 | 0 | 2 | 4 | 1 | 2 | SearchInput |  |
| `spheres/social/ui/CampaignWizard.tsx` | 1 | 8 | 2 | 4 | 1 | 2 | CampaignWizard |  |
| `spheres/social/ui/useAutoSweep.ts` | 1 | 2 | 2 | 4 | 1 | 2 | LAST_KEY, SWEEP_MS, useAutoSweep, stampDispatch, lastDispatchAt |  |
| `spheres/financial/api/policy.js` | 1 | 0 | 2 | 4 | 1 | 2 | dealsClaims, frozenClaims, claimedDealsCampaigns |  |
| `agent/server.js` | 0 | 5 | 2 | 2 | 2 | 2 | newTurn, TLS_KEY, BODY_CAP, TLS_CERT, logDetail, logRequest |  |
| `server/shared/db-errors.js` | 7 | 0 | 8 | 9 | 1 | 1 | db-errors |  |
| `connectors/clover/api/sync.js` | 1 | 0 | 1 | 1 | 1 | 1 | syncOrders, localZoneOf, watermarkMs |  |
| `scripts/import-env-credentials.mjs` | 0 | 7 | 1 | 1 | 1 | 1 | import-env-credentials |  |
| `spheres/social/ui/components.tsx` | 6 | 4 | 6 | 66 | 0 | 0 | ageOf, msgLine, FacetTags, dateRange, MsgPreview, CollabStat |  |
| `spheres/schedule/api/valid.js` | 4 | 0 | 4 | 21 | 0 | 0 | isHHMM, HHMM_RE, DATE_RE, spanDays, isISODate |  |
| `spheres/financial/ui/letterhead.ts` | 3 | 3 | 3 | 14 | 0 | 0 | useTenants, TenantInfo, Letterhead, soleCountry, letterheadFor |  |
| `spheres/schedule/ui/cards.tsx` | 3 | 3 | 3 | 8 | 0 | 0 | timeFace, EntryCard, shortDate, PeopleGlyph |  |
| `web/src/lib/use-anchor.ts` | 2 | 2 | 2 | 8 | 0 | 0 | useAnchor, use-anchor |  |
| `web/src/lib/stream.ts` | 2 | 0 | 2 | 16 | 0 | 0 | isAbort, readSse, onFrame, postSse, SseFrame, StreamAuth |  |
| `web/src/app/AccessGrants.tsx` | 2 | 2 | 2 | 18 | 0 | 0 | refOf, ownToken, VerbState, GrantCell, ownExport, roleCover |  |
| `spheres/coord/ui/windows.tsx` | 2 | 3 | 2 | 8 | 0 | 0 | isWindow, WindowChips, useWindowParam |  |
| `spheres/library/ui/ItemOverlay.tsx` | 2 | 7 | 2 | 6 | 0 | 0 | ItemOverlay |  |
| `spheres/reputation/ui/PlaceChips.tsx` | 2 | 4 | 2 | 10 | 0 | 0 | PlaceChips, usePlaceParam |  |
| `spheres/social/ui/sweep.ts` | 2 | 1 | 2 | 4 | 0 | 0 | dispatchSweep |  |
| `server/shared/model-retry.js` | 2 | 0 | 2 | 8 | 0 | 0 | model-retry, sendWithRetry, FIVEXX_BACKOFF_MS |  |
| `web/src/app/chat-icon.tsx` | 1 | 0 | 1 | 4 | 0 | 0 | chatIcon, chat-icon |  |
| `web/src/app/AccessTenants.tsx` | 1 | 6 | 1 | 3 | 0 | 0 | OrgRow, OrgDrawer, AccessTenants |  |
| `spheres/relationships/ui/views/PersonPanel.tsx` | 1 | 6 | 1 | 7 | 0 | 0 | onGone, PersonPanel, ProfileStats |  |
| `spheres/reputation/ui/views/NeedsReply.tsx` | 1 | 10 | 1 | 4 | 0 | 0 | NeedsReply |  |
| `spheres/social/ui/drafts.tsx` | 1 | 6 | 1 | 3 | 0 | 0 | onPatch, DraftDrawer |  |
| `spheres/social/ui/CampaignsSection.tsx` | 1 | 10 | 1 | 4 | 0 | 0 | CampRoute, routeFromPath, CampaignsSection |  |
| `spheres/social/ui/useUnreadNotifier.ts` | 1 | 2 | 1 | 3 | 0 | 0 | useUnreadNotifier |  |
| `spheres/social/ui/PerformanceChart.tsx` | 1 | 3 | 1 | 5 | 0 | 0 | niceMax, useWidth, PerformanceChart |  |
| `spheres/projects/api/statements.js` | 1 | 0 | 1 | 11 | 0 | 0 | clearBall, deleteLink, upsertLink, updateBall, insertEvent, upsertVerdict |  |
| `spheres/social/api/statements.js` | 2 | 0 | 1 | 2 | 0 | 0 | insertSubset |  |
| `agent/transcribe.js` | 1 | 0 | 1 | 4 | 0 | 0 | dialogueOf, MAX_AUDIO_BYTES, transcribeChannel, transcribeEnabled, transcribeAuthorized |  |
| `web/src/app/spheres.ts` | 2 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `web/src/app/Access.tsx` | 1 | 11 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `web/src/main.tsx` | 0 | 2 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `web/src/vite-env.d.ts` | 1 | 0 | 0 | 0 | 0 | 0 | vite-env.d |  |
| `web/src/pipeline/Campaigns.tsx` | 3 | 8 | 0 | 0 | 0 | 0 | CampaignCard |  |
| `spheres/coord/ui/views/Board.tsx` | 1 | 10 | 0 | 0 | 0 | 0 | columnOf |  |
| `spheres/coord/ui/sphere.tsx` | 0 | 4 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/customer-service/ui/views/Calls.tsx` | 1 | 11 | 0 | 0 | 0 | 0 | hadOne, sliceFor, foldDays, LOG_SLICE, TenantSlice, foldRepDays |  |
| `spheres/customer-service/ui/sphere.tsx` | 0 | 2 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/financial/ui/views/Products.tsx` | 1 | 13 | 0 | 0 | 0 | 0 | MoveChip, CHANNEL_NAME |  |
| `spheres/financial/ui/views/People.tsx` | 1 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/financial/ui/views/Deals.tsx` | 1 | 4 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/financial/ui/sphere.tsx` | 0 | 6 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/library/ui/views/Media.tsx` | 1 | 6 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/library/ui/views/Documents.tsx` | 1 | 6 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/library/ui/sphere.tsx` | 0 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/partnership/ui/api.ts` | 2 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/partnership/ui/views/Roster.tsx` | 1 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/partnership/ui/views/Campaigns.tsx` | 1 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/partnership/ui/sphere.tsx` | 0 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/projects/ui/views/Portfolio.tsx` | 1 | 12 | 0 | 0 | 0 | 0 | ProjectCard, PortfolioBoard |  |
| `spheres/projects/ui/sphere.tsx` | 0 | 2 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/publicity/ui/views/Roster.tsx` | 1 | 4 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/publicity/ui/views/Campaigns.tsx` | 1 | 4 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/publicity/ui/sphere.tsx` | 0 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/relationships/ui/views/People.tsx` | 1 | 10 | 0 | 0 | 0 | 0 | handleOf, stagePills, subtitleOf, presenceMarks, SOURCE_OPTIONS |  |
| `spheres/relationships/ui/sphere.tsx` | 0 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/reputation/ui/sphere.tsx` | 0 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/schedule/ui/views/Week.tsx` | 1 | 14 | 0 | 0 | 0 | 0 | draftOf, ISO_DAY, parseWeek, rangeLabel, serializeWeek, PendingConfirm |  |
| `spheres/schedule/ui/sphere.tsx` | 0 | 4 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/social/ui/sphere.tsx` | 0 | 4 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/awsconnect/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/awsconnect/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/awsconnect/sync.js` | 0 | 5 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/clover/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/clover/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/clover/sync.js` | 0 | 7 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/deputy/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/deputy/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/deputy/sync.js` | 0 | 7 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/dropbox/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/dropbox/api/consent.js` | 0 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/dropbox/api/probe.js` | 0 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/facebook/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/github/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/github/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 | subscriptionCount |  |
| `connectors/github/api/formats.js` | 1 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/github/api/sync.js` | 1 | 0 | 0 | 0 | 0 | 0 | loadShas, touchFile, upsertFile |  |
| `connectors/github/sync.js` | 0 | 7 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/googlechat/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/googlechat/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/googlechat/sync.js` | 0 | 6 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/googlereviews/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/googlereviews/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/googlereviews/sync.js` | 0 | 6 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/instagram/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/instagram/jobs.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/linkedin/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/linkedin/jobs.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/onedrive/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/onedrive/api/consent.js` | 0 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/onedrive/api/probe.js` | 0 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/otter/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/otter/jobs.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/rezdy/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/rezdy/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/rezdy/api/sync.js` | 1 | 0 | 0 | 0 | 0 | 0 | syncPerCategory |  |
| `connectors/rezdy/sync.js` | 0 | 7 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/sonas/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/sonas/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/sonas/api/sync.js` | 1 | 0 | 0 | 0 | 0 | 0 | syncPub, syncTabular, syncTabularDetail |  |
| `connectors/sonas/sync.js` | 0 | 7 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/spar/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/spar/sync.js` | 0 | 4 | 0 | 0 | 0 | 0 | readText, listFiles |  |
| `connectors/square/import.js` | 0 | 4 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/tiktok/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/xero/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/xero/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `connectors/xero/api/sync.js` | 1 | 1 | 0 | 0 | 0 | 0 | OFFSET_CHUNK, syncSettings, syncPaginated, syncOffsetWalk, newWatermarkMs, setOffsetCursor |  |
| `connectors/xero/sync.js` | 0 | 6 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/coord/reconstruct.js` | 0 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `server/shared/dispatch.js` | 12 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `server/shared/freshness.js` | 5 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/customer-service/api/instance.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/financial/api/statements.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/financial/api/instance.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/library/api/providers.js` | 1 | 3 | 0 | 0 | 0 | 0 | appCreds |  |
| `spheres/library/api/instance.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/partnership/api/policy.js` | 1 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/partnership/api/statements.js` | 0 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/partnership/api/read.js` | 1 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/partnership/api/instance.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/projects/api/policy.js` | 1 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/projects/api/instance.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/publicity/api/policy.js` | 3 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/publicity/api/statements.js` | 1 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/publicity/api/instance.js` | 0 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/relationships/api/read.js` | 1 | 5 | 0 | 0 | 0 | 0 | jsonStr, groupName, tripleKey, matchSide, personJson, loadRecords |  |
| `spheres/relationships/api/instance.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/reputation/api/policy.js` | 1 | 0 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/reputation/api/read.js` | 1 | 2 | 0 | 0 | 0 | 0 | cleanText, listPlaces, listReviews, undismissReview |  |
| `spheres/reputation/api/instance.js` | 0 | 1 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/schedule/api/providers/index.js` | 3 | 3 | 0 | 0 | 0 | 0 |  | no distinctive vocabulary; B not measured |
| `spheres/schedule/api/instance.js` | 0 | 2 | 0 | 0 | 0 | 0 | reconcileDue |  |

## Conventions — one name, several defining files

A name several files define is not erased: it is a concept with several homes, the interface of a family of sibling modules. A and B are over all its homes.

| name | homes | A | B | C | homes sample |
|---|---:|---:|---:|---:|---|
| `fakeConn` | 30 | 0 | 0 | 0 | `server/shared/auth.test.js`, `server/shared/chat.test.js`, `server/shared/connector-health.test.js`, `server/shared/freshness.test.js` |
| `params` | 22 | 5 | 137 | 775 | `agent/error-codes.js`, `connectors/clover/api/clover-client.js`, `connectors/dropbox/api/dropbox-client.js`, `connectors/facebook/api/graph-client.js` |
| `makeFakeConn` | 18 | 0 | 0 | 0 | `connectors/awsconnect/api/sync.test.js`, `connectors/awsconnect/api/upsert.test.js`, `connectors/clover/api/sync.test.js`, `connectors/clover/api/upsert.test.js` |
| `config` | 16 | 0 | 184 | 690 | `connectors/instagram/jobs.js`, `connectors/linkedin/jobs.js`, `connectors/otter/jobs.js`, `server/shared/contract.js` |
| `loadConfig` | 16 | 3 | 6 | 20 | `connectors/awsconnect/sync.js`, `connectors/clover/sync.js`, `connectors/deputy/sync.js`, `connectors/facebook/insights-sync.js` |
| `timeoutMs` | 14 | 0 | 9 | 32 | `connectors/clover/api/clover-client.js`, `connectors/facebook/api/graph-client.js`, `connectors/github/api/github-client.js`, `connectors/googlechat/api/chat-client.js` |
| `handleApi` | 13 | 12 | 42 | 373 | `server/shared/contract.js`, `server/shared/party.js`, `spheres/coord/api/read.js`, `spheres/customer-service/api/read.js` |
| `onClose` | 13 | 14 | 20 | 46 | `spheres/coord/ui/views/MeetingFollowUp.tsx`, `spheres/customer-service/ui/views/Calls.tsx`, `spheres/library/ui/ItemOverlay.tsx`, `spheres/projects/ui/views/Gantt.tsx` |
| `nowMysql` | 11 | 0 | 1 | 1 | `connectors/awsconnect/api/upsert.js`, `connectors/clover/api/upsert.js`, `connectors/deputy/api/upsert.js`, `connectors/googlereviews/api/upsert.js` |
| `runSyncPass` | 9 | 9 | 18 | 134 | `connectors/awsconnect/api/sync.js`, `connectors/clover/api/sync.js`, `connectors/deputy/api/sync.js`, `connectors/github/api/sync.js` |
| `httpRaw` | 9 | 10 | 10 | 21 | `connectors/clover/api/clover-client.js`, `connectors/github/api/github-client.js`, `connectors/rezdy/api/rezdy-client.js`, `connectors/square/api/square-client.js` |
| `defaultSleep` | 9 | 2 | 2 | 4 | `connectors/awsconnect/api/aws-client.js`, `connectors/clover/api/clover-client.js`, `connectors/deputy/api/deputy-client.js`, `connectors/dropbox/api/dropbox-client.js` |
| `INTERVAL_MIN` | 9 | 0 | 0 | 0 | `connectors/awsconnect/hook.js`, `connectors/clover/hook.js`, `connectors/deputy/hook.js`, `connectors/github/hook.js` |
| `makeFakeClient` | 9 | 0 | 0 | 0 | `connectors/awsconnect/api/sync.test.js`, `connectors/clover/api/sync.test.js`, `connectors/deputy/api/sync.test.js`, `connectors/github/api/sync.test.js` |
| `MAX_RETRY_AFTER_MS` | 9 | 0 | 0 | 0 | `connectors/clover/api/clover-client.js`, `connectors/deputy/api/deputy-client.js`, `connectors/dropbox/api/dropbox-client.js`, `connectors/github/api/github-client.js` |
| `onOpen` | 8 | 7 | 21 | 47 | `spheres/library/ui/Results.tsx`, `spheres/social/ui/CampaignBoard.tsx`, `spheres/social/ui/CampaignPipeline.tsx`, `spheres/social/ui/Rolodex.tsx` |
| `retryAfterMs` | 8 | 0 | 2 | 9 | `connectors/clover/api/clover-client.js`, `connectors/deputy/api/deputy-client.js`, `connectors/dropbox/api/dropbox-client.js`, `connectors/onedrive/api/graph-client.js` |
| `runbook` | 7 | 0 | 55 | 223 | `server/shared/anthropic.js`, `server/shared/deepseek.js`, `server/shared/model-api.js`, `server/shared/ollama.js` |
| `tradeVocab` | 7 | 2 | 16 | 40 | `spheres/social/ui/CampaignBoard.tsx`, `spheres/social/ui/CampaignPipeline.tsx`, `spheres/social/ui/CampaignWizard.tsx`, `spheres/social/ui/ContactDetail.tsx` |
| `withRetry` | 7 | 0 | 8 | 15 | `connectors/dropbox/api/dropbox-client.js`, `connectors/facebook/api/graph-client.js`, `connectors/googlechat/api/chat-client.js`, `connectors/googlereviews/api/serpapi-client.js` |
| `callsFor` | 7 | 0 | 0 | 0 | `connectors/awsconnect/api/upsert.test.js`, `connectors/clover/api/upsert.test.js`, `connectors/deputy/api/upsert.test.js`, `connectors/rezdy/api/upsert.test.js` |
| `SCHEMA_COLS` | 7 | 0 | 0 | 0 | `connectors/clover/api/upsert.test.js`, `connectors/deputy/api/upsert.test.js`, `connectors/rezdy/api/upsert.test.js`, `connectors/sonas/api/upsert.test.js` |
| `entryStage` | 6 | 9 | 26 | 52 | `spheres/projects/api/derive.js`, `web/src/pipeline/Campaigns.tsx`, `web/src/pipeline/ContactPanel.tsx`, `web/src/pipeline/Roster.tsx` |
| `upsertEntity` | 6 | 6 | 20 | 103 | `connectors/clover/api/upsert.js`, `connectors/deputy/api/upsert.js`, `connectors/rezdy/api/upsert.js`, `connectors/sonas/api/upsert.js` |
| `ENTITY_BY_KEY` | 6 | 1 | 8 | 90 | `connectors/clover/api/upsert.js`, `connectors/deputy/api/upsert.js`, `connectors/rezdy/api/upsert.js`, `connectors/sonas/api/upsert.js` |
| `memberOf` | 6 | 0 | 2 | 3 | `server/shared/spar-pipeline.js`, `spheres/projects/api/read.js`, `spheres/publicity/api/cursor.test.js`, `spheres/publicity/api/stage-advance.js` |
| `DAY_MS` | 6 | 0 | 1 | 2 | `connectors/awsconnect/api/sync.js`, `spheres/reputation/ui/lanes.ts`, `spheres/schedule/api/providers/rezdy.js`, `spheres/schedule/api/reconcile-logic.js` |
| `finishEntity` | 6 | 0 | 1 | 1 | `connectors/awsconnect/api/sync.js`, `connectors/clover/api/sync.js`, `connectors/deputy/api/sync.js`, `connectors/rezdy/api/sync.js` |
| `touchEntity` | 6 | 0 | 1 | 1 | `connectors/awsconnect/api/sync.js`, `connectors/clover/api/sync.js`, `connectors/deputy/api/sync.js`, `connectors/rezdy/api/sync.js` |
| `loadCursors` | 6 | 0 | 1 | 1 | `connectors/clover/api/sync.js`, `connectors/deputy/api/sync.js`, `connectors/googlechat/api/sync.js`, `connectors/rezdy/api/sync.js` |
| `makeClient` | 6 | 0 | 1 | 9 | `connectors/deputy/api/client.test.js`, `connectors/dropbox/api/dropbox-client.test.js`, `connectors/github/api/client.test.js`, `connectors/onedrive/api/graph-client.test.js` |
| `seedCursors` | 6 | 0 | 0 | 0 | `connectors/awsconnect/api/sync.js`, `connectors/clover/api/sync.js`, `connectors/deputy/api/sync.js`, `connectors/rezdy/api/sync.js` |
| `passDeps` | 6 | 0 | 0 | 0 | `connectors/awsconnect/api/sync.test.js`, `connectors/clover/api/sync.test.js`, `connectors/deputy/api/sync.test.js`, `connectors/googlereviews/api/sync.test.js` |
| `upsertSQL` | 6 | 0 | 0 | 0 | `connectors/clover/api/upsert.js`, `connectors/deputy/api/upsert.js`, `connectors/rezdy/api/upsert.js`, `connectors/sonas/api/upsert.js` |
| `nowMs` | 5 | 0 | 37 | 124 | `connectors/deputy/api/client.test.js`, `connectors/github/api/client.test.js`, `connectors/github/api/github-client.js`, `connectors/rezdy/api/client.test.js` |
| `authed` | 5 | 0 | 28 | 202 | `spheres/financial/api/deals.test.js`, `spheres/partnership/api/read.test.js`, `spheres/projects/api/read.test.js`, `spheres/publicity/api/read.test.js` |
| `Campaigns` | 5 | 1 | 24 | 45 | `spheres/partnership/ui/sphere.tsx`, `spheres/partnership/ui/views/Campaigns.tsx`, `spheres/publicity/ui/sphere.tsx`, `spheres/publicity/ui/views/Campaigns.tsx` |
| `Roster` | 5 | 1 | 17 | 31 | `spheres/partnership/ui/sphere.tsx`, `spheres/partnership/ui/views/Roster.tsx`, `spheres/publicity/ui/sphere.tsx`, `spheres/publicity/ui/views/Roster.tsx` |
| `campaignId` | 5 | 2 | 16 | 46 | `spheres/relationships/ui/api.ts`, `spheres/social/api/read.js`, `spheres/social/ui/api.ts`, `spheres/social/ui/cards.tsx` |
| `insertFlip` | 5 | 4 | 12 | 29 | `spheres/financial/api/statements.js`, `spheres/partnership/api/statements.js`, `spheres/projects/api/statements.js`, `spheres/publicity/api/statements.js` |
| `audienceVocab` | 5 | 2 | 11 | 29 | `spheres/social/ui/CampaignWizard.tsx`, `spheres/social/ui/ContactDetail.tsx`, `spheres/social/ui/Rolodex.tsx`, `spheres/social/ui/cards.tsx` |
| `isoToMysql` | 5 | 4 | 10 | 44 | `connectors/googlechat/api/sync.js`, `connectors/googlereviews/api/upsert.js`, `connectors/instagram/api/jobs.js`, `connectors/rezdy/api/upsert.js` |
| `msToMysql` | 5 | 0 | 1 | 2 | `connectors/awsconnect/api/sync.js`, `connectors/clover/api/upsert.js`, `connectors/deputy/api/sync.js`, `connectors/xero/api/sync.js` |
| `callIndex` | 5 | 0 | 1 | 1 | `connectors/deputy/api/upsert.test.js`, `connectors/rezdy/api/upsert.test.js`, `connectors/sonas/api/upsert.test.js`, `connectors/spar/api/upsert.test.js` |
| `makeClock` | 5 | 0 | 0 | 0 | `connectors/deputy/api/client.test.js`, `connectors/dropbox/api/dropbox-client.test.js`, `connectors/github/api/client.test.js`, `connectors/onedrive/api/graph-client.test.js` |
| `makeHttp` | 5 | 0 | 0 | 0 | `connectors/deputy/api/client.test.js`, `connectors/dropbox/api/dropbox-client.test.js`, `connectors/github/api/client.test.js`, `connectors/onedrive/api/graph-client.test.js` |
| `dataset` | 4 | 4 | 99 | 646 | `spheres/library/ui/api.ts`, `web/src/app/AccessGrants.tsx`, `web/src/lib/auth.ts`, `web/src/lib/grants.ts` |
| `People` | 4 | 0 | 36 | 69 | `spheres/financial/ui/sphere.tsx`, `spheres/financial/ui/views/People.tsx`, `spheres/relationships/ui/sphere.tsx`, `spheres/relationships/ui/views/People.tsx` |
| `createdAt` | 4 | 4 | 22 | 36 | `spheres/coord/ui/api.ts`, `spheres/customer-service/ui/api.ts`, `spheres/projects/ui/api.ts`, `spheres/relationships/ui/api.ts` |
| `fmtDate` | 4 | 18 | 21 | 79 | `spheres/coord/ui/views/ByPerson.tsx`, `spheres/relationships/ui/views/PersonPanel.tsx`, `web/src/lib/format.ts`, `web/src/pipeline/api.ts` |
| `toStart` | 4 | 1 | 10 | 27 | `spheres/schedule/api/providers/local.js`, `spheres/schedule/ui/ConfirmMove.tsx`, `spheres/schedule/ui/api.ts`, `spheres/schedule/ui/views/Week.tsx` |
| `authorizeUrl` | 4 | 4 | 8 | 22 | `connectors/dropbox/api/dropbox-client.js`, `connectors/onedrive/api/graph-client.js`, `connectors/tiktok/api/tiktok-client.js`, `connectors/xero/api/xero-client.js` |
| `legalName` | 4 | 0 | 7 | 30 | `spheres/financial/ui/letterhead.ts`, `web/src/app/AccessTenants.tsx`, `web/src/lib/auth.ts`, `web/src/lib/org-identity.ts` |
| `taxLabel` | 4 | 0 | 7 | 25 | `spheres/financial/ui/letterhead.ts`, `web/src/app/AccessTenants.tsx`, `web/src/lib/auth.ts`, `web/src/lib/org-identity.ts` |
| `taxId` | 4 | 0 | 7 | 24 | `spheres/financial/ui/letterhead.ts`, `web/src/app/AccessTenants.tsx`, `web/src/lib/auth.ts`, `web/src/lib/org-identity.ts` |
| `addressLine1` | 4 | 0 | 7 | 17 | `spheres/financial/ui/letterhead.ts`, `web/src/app/AccessTenants.tsx`, `web/src/lib/auth.ts`, `web/src/lib/org-identity.ts` |
| `addressLine2` | 4 | 0 | 6 | 16 | `spheres/financial/ui/letterhead.ts`, `web/src/app/AccessTenants.tsx`, `web/src/lib/auth.ts`, `web/src/lib/org-identity.ts` |
| `stagePass` | 4 | 2 | 6 | 14 | `spheres/publicity/api/instance.js`, `spheres/publicity/api/stage-advance.js`, `spheres/social/api/instance.js`, `spheres/social/api/stage-advance.js` |
| `Freshness` | 4 | 1 | 5 | 8 | `spheres/customer-service/ui/api.ts`, `spheres/relationships/ui/api.ts`, `web/src/pipeline/api.ts`, `web/src/ui/FreshnessNote.tsx` |
| `onDone` | 4 | 3 | 4 | 16 | `spheres/customer-service/ui/views/Calls.tsx`, `spheres/schedule/ui/EntryEditor.tsx`, `spheres/social/ui/CampaignWizard.tsx`, `web/src/lib/chat.ts` |
