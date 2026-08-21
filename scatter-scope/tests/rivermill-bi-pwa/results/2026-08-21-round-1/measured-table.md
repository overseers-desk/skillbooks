# Measured table (Count)

Produced by `tools/scope-count.py` from the merged SCIP index and the tree.
A = non-test source files outside the module that reference a symbol it defines (graph).
B = files of any kind that mention a name in its vocabulary (grep). C = total mentions.
leak = B minus the files the graph already counted. score = C x leak/B.

| score | leak | A | B | C | lines | module | vocabulary sample |
|---:|---:|---:|---:|---:|---:|---|---|
| 1070 | 90 | 16 | 104 | 1236 | 331 | `web/src/pipeline/api.ts` | r_note, s_note, p_note, a_note, hasNote, relTime |
| 722 | 235 | 4 | 238 | 731 | 109 | `spheres/schedule/api/providers/local.js` | local, toMin, shiftEnd, MOVE_SQL, getEntry |
| 586 | 106 | 11 | 114 | 630 | 480 | `web/src/lib/auth.ts` | AppRun, addedAt, addedBy, AppUser, authHint, grantsOf |
| 440 | 89 | 3 | 92 | 455 | 300 | `spheres/relationships/ui/api.ts` | userId, eventId, claimId, lastname, linkedin, removedAt |
| 426 | 37 | 2 | 39 | 449 | 144 | `web/src/ui/FilterBar.tsx` | onAll, onNone, optionsOf, FilterBar, FilterCheck, FacetButton |
| 419 | 57 | 2 | 59 | 434 | 108 | `web/src/lib/stream.ts` | stream, isAbort, readSse, postSse, onFrame, SseFrame |
| 399 | 48 | 15 | 59 | 490 | 589 | `spheres/social/ui/api.ts` | tiktok, sentAt, LastMsg, takenAt, PerfPost, GrowthRow |
| 353 | 29 | 3 | 32 | 389 | 1026 | `spheres/social/ui/Rolodex.tsx` | NO_STAR, onSweep, listIcon, isSoured, gridIcon, setQuery |
| 298 | 101 | 6 | 107 | 316 | 195 | `web/src/ui/CtxMenu.tsx` | CtxSub, CtxMenu, CtxItem, viewport, CtxButton, subOffsets |
| 286 | 77 | 1 | 78 | 290 | 215 | `spheres/schedule/api/providers/rezdy.js` | rezdy, GRID_SQL, deriveSlots, OCCUPANCY_SQL |
| 276 | 36 | 0 | 36 | 276 | 25 | `server/shared/testdb.js` | testdb, withTxn |
| 263 | 22 | 4 | 26 | 311 | 182 | `web/src/ui/boardDrag.ts` | onDrop, onLift, canDrag, specFor, fromKey, dropSpec |
| 259 | 37 | 44 | 51 | 357 | 77 | `web/src/ui/atoms.tsx` | PillTone, AvatarSize, CountBadge, StatusPill |
| 243 | 38 | 7 | 43 | 275 | 281 | `spheres/schedule/ui/api.ts` | footer, moveId, TermRow, fromDate, MoveBody, postMove |
| 220 | 42 | 3 | 44 | 230 | 1679 | `server/shared/auth.js` | newCode, startMs, codeStr, newToken, sendMail, setPrefs |
| 209 | 22 | 2 | 24 | 228 | 151 | `spheres/social/ui/CampaignPipeline.tsx` | onNew, onPeople, selectedId, CampaignList, deleteAction, CampaignPipeline |
| 196 | 11 | 1 | 12 | 214 | 164 | `spheres/customer-service/ui/api.ts` | agentId, CallDay, CallRow, CallRep, rangOut, waitSecs |
| 189 | 57 | 38 | 95 | 315 | 165 | `web/src/lib/use-api-view.ts` | paramsOf, staleTime, useApiView, apiViewKey, apiViewPath, resolveRoute |
| 177 | 51 | 11 | 62 | 215 | 75 | `web/src/ui/Overlay.tsx` | Overlay, panelClassName |
| 170 | 55 | 3 | 58 | 179 | 45 | `spheres/publicity/ui/api.ts` | created_at, addCoverage, coverageCount, CoverageCount, CoverageInput, published_date |
| 166 | 43 | 9 | 52 | 201 | 69 | `web/src/ui/ParamChips.tsx` | allLabel, ParamChips, ChipOption |
| 161 | 37 | 0 | 37 | 161 | 804 | `scripts/import-meta-exports.mjs` | winKey, mdyToIso, basename, fileLabel, permalink, postIdCell |
| 157 | 59 | 19 | 78 | 207 | 37 | `web/src/ui/SectionHeader.tsx` | SectionHeader |
| 155 | 39 | 26 | 65 | 259 | 199 | `server/shared/sync-runs.js` | endRun, syncDue, BEAT_MS, syncBusy, beginRun, elapsedMs |
| 152 | 54 | 8 | 62 | 175 | 101 | `web/src/ui/DeepLink.tsx` | DeepLink |
| 152 | 3 | 2 | 5 | 254 | 689 | `spheres/social/ui/perf-derive.ts` | DAY_RE, DayRow, PerfRow, SortKey, ChartRow, deltasOf |
| 149 | 24 | 1 | 25 | 155 | 115 | `spheres/financial/ui/fy.ts` | fy, FYRow, fyRows, fyYear, fyLabel, fyWindow |
| 136 | 16 | 28 | 38 | 324 | 121 | `web/src/lib/format.ts` | prefs, fmtParts, weekStart, DateOrder, dateOrder, fmtRegion |
| 133 | 45 | 11 | 56 | 166 | 57 | `web/src/ui/FreshnessNote.tsx` | FreshnessNote |
| 126 | 29 | 3 | 32 | 139 | 72 | `web/src/ui/SelectableCard.tsx` | openLabel, SelectableCard |
| 125 | 32 | 3 | 35 | 137 | 66 | `web/src/ui/PersonRow.tsx` | PersonRow |
| 121 | 9 | 1 | 10 | 134 | 208 | `spheres/financial/ui/export.ts` | setOff, NUM_FMT, viewWord, localName, sheetName, viewLabel |
| 120 | 45 | 20 | 65 | 174 | 131 | `web/src/lib/url-state.ts` | readRaw, url-state, writeParam, useUrlParam, useStringParam |
| 120 | 27 | 30 | 57 | 254 | 34 | `web/src/ui/ReachNote.tsx` | useReach, ReachNote |
| 119 | 9 | 2 | 11 | 146 | 272 | `spheres/projects/ui/api.ts` | notedBy, notedAt, locator, setBall, stageAt, LivesAt |
| 118 | 19 | 1 | 20 | 124 | 329 | `server/shared/ready.js` | staleIds, freshIds, workQueue, readyWork, makeReader, describeWork |
| 118 | 5 | 3 | 6 | 141 | 224 | `server/shared/grants.js` | needVerb, VERB_ORDER, DATA_TOKEN, formatToken, parseGrants, warnedTokens |
| 108 | 42 | 8 | 50 | 129 | 108 | `web/src/lib/view-registry.ts` | nextId, ChoiceSet, view-registry, anchorElement, registerAnchor, registerChoice |
| 107 | 22 | 3 | 25 | 122 | 38 | `web/src/ui/Chips.tsx` | ChipRow |
| 106 | 28 | 3 | 31 | 117 | 51 | `web/src/ui/GroupedList.tsx` | renderBody, GroupedList |
| 104 | 21 | 7 | 28 | 138 | 445 | `web/src/ui/Board.tsx` | DropZone, DragCard, snapIndex, DragBoard, DropColumn, scrollLeft |
| 103 | 12 | 5 | 15 | 129 | 71 | `spheres/reputation/ui/api.ts` | avgRating, localGuide, totalScore, placeTitle, publishedAt, ownerResponse |
| 103 | 11 | 3 | 14 | 131 | 45 | `connectors/instagram/api/shortcode.js` | shortcode, IG_ALPHABET, shortcodeToPk, pkToShortcode, shortcodeFromPermalink |
| 102 | 50 | 0 | 50 | 102 | 302 | `connectors/awsconnect/api/sync.test.js` | upserts, dimHandlers |
| 98 | 18 | 5 | 21 | 114 | 204 | `spheres/coord/ui/api.ts` | sweepNow, TaskState, LeaderRow, sourceKind, methodDate, createTime |
| 97 | 19 | 0 | 19 | 97 | 235 | `scripts/refresh-meta-recent.mjs` | skillRef, runSkill, faultText, overseerUp, IG_HANDLES, resolveOwnPk |
| 94 | 20 | 1 | 21 | 99 | 36 | `web/src/ui/HoverTip.tsx` | HoverTip |
| 93 | 17 | 2 | 18 | 98 | 86 | `spheres/library/api/hits.js` | Q_MAX, HIT_KINDS, isNotFound, PAGE_LIMIT, EMPTY_SEARCH, searchParams |
| 92 | 34 | 5 | 39 | 105 | 623 | `server/shared/spar-pipeline.js` | claimSql, LAST_TOUCH, loadClaims, configPath, MEMBER_SQL, memberJson |
| 80 | 13 | 11 | 18 | 111 | 181 | `web/src/lib/journey.ts` | loadSeq, saveTail, sphereOf, loadTail, JourneyVerb, JOURNEY_CAP |
| 77 | 24 | 8 | 32 | 103 | 57 | `web/src/lib/navigate.ts` | navigate, closeSecondary |
| 70 | 20 | 21 | 41 | 144 | 45 | `server/shared/connector-tenant.js` | tenantOf, connector-tenant |
| 67 | 22 | 2 | 24 | 73 | 8 | `server/shared/hash.js` | sha256 |
| 66 | 20 | 0 | 20 | 66 | 45 | `spheres/social/api/instance.js` | loadVocab, stagePassDue |
| 65 | 20 | 6 | 26 | 84 | 74 | `server/shared/job-runs.js` | runBase, job-runs, runBPersist, normalizeResolvedVersion |
| 62 | 20 | 0 | 20 | 62 | 421 | `server/shared/access.test.js` | agentP, machineP, PL_EMPTY, openDecl, listDecl, noSession |
| 62 | 8 | 1 | 9 | 70 | 512 | `connectors/instagram/api/insights-sync.js` | dayUtc, ownerPk, mediaPk, pollSet, fullWalk, dayBounds |
| 61 | 5 | 0 | 5 | 61 | 755 | `scripts/import-otter-corpus.mjs` | fmDoc, mdBody, fmText, asArray, inLedger, stemDate |
| 58 | 27 | 3 | 30 | 64 | 18 | `web/src/lib/breakpoint.ts` | breakpoint, useDesktop, DESKTOP_QUERY, DESKTOP_MIN_PX, subscribeDesktop |
| 58 | 5 | 1 | 6 | 70 | 138 | `spheres/projects/api/derive.js` | prereqId, statusAt, statusOf, prereqsOf, wouldCycle, dependentId |
| 56 | 25 | 6 | 31 | 70 | 34 | `web/src/lib/clicklog.ts` | clicklog, logDeepLink, openDeepLink |
| 55 | 10 | 3 | 11 | 61 | 559 | `connectors/instagram/api/jobs.js` | longId, shortPk, viewerId, DUMP_SQL, normCount, handlesOf |
| 54 | 15 | 6 | 21 | 75 | 234 | `web/src/app/AuthGate.tsx` | AuthCtx, AuthGate, onSignedIn, LoginScreen, AuthUpdateCtx, applyStoredPrefs |
| 54 | 8 | 1 | 9 | 61 | 202 | `agent/tools.js` | BI_BASE, rowFault, toolNames, toolEntries, deriveTools, fetchEntries |
| 53 | 14 | 24 | 38 | 145 | 278 | `server/shared/credentials.js` | fieldOf, readToken, updatedBy, writeToken, setCredential, clearCredential |
| 52 | 5 | 1 | 5 | 52 | 579 | `connectors/linkedin/api/jobs.js` | isSelf, ownerUrn, profileUrn, connectedAt, connectedUrn, validateInbox |
| 50 | 12 | 2 | 14 | 58 | 63 | `server/shared/anthropic.js` | anthropic, MODEL_IDS, runRunbook |
| 50 | 5 | 7 | 12 | 120 | 100 | `web/src/lib/slot-store.ts` | wakeView, SlotView, clearSlot, wakeParam, slot-store, getSnapshot |
| 50 | 6 | 2 | 8 | 66 | 109 | `spheres/financial/ui/matrix.ts` | perfNet, DisplayRow, MonthMatrix, modifierNet, monthMatrix, perfSegments |
| 50 | 2 | 1 | 3 | 75 | 137 | `spheres/financial/ui/labour-matrix.ts` | round1, unitIds, wagePct, perUnit, unitNames, LabourDay |
| 49 | 11 | 34 | 34 | 151 | 121 | `web/src/lib/api.ts` | apiGet, apiPost, ApiError, refusalOf |
| 49 | 15 | 2 | 17 | 56 | 211 | `connectors/xero/api/xero-client.js` | xero-client, extractList, accessToken, PRODUCT_BASES, makeXeroClient, CONNECTIONS_URL |
| 48 | 11 | 4 | 15 | 65 | 159 | `server/shared/walls.js` | pairKey, WAGES_WALL, wallContext, placeholders, warnedNoWalls, missingTables |
| 47 | 5 | 3 | 7 | 66 | 91 | `spheres/schedule/ui/week.ts` | DayCell, isToday, todayIso, mondayOf, weekRange, weekCells |
| 47 | 3 | 0 | 3 | 47 | 238 | `connectors/awsconnect/api/upsert.js` | fmtFor, DAY_NUM, localOf, fmtCache, tsToMysql, upsertUsers |
| 44 | 25 | 1 | 26 | 46 | 115 | `agent/transcribe.js` | dialogueOf, transcribe, MAX_AUDIO_BYTES, transcribeChannel, transcribeEnabled, transcribeAuthorized |
| 44 | 18 | 3 | 21 | 51 | 142 | `web/src/ui/useCardSelection.ts` | groupFor, shiftKey, ClickLike, CardGestures, CardSelection, useCardSelection |
| 44 | 3 | 6 | 9 | 131 | 366 | `spheres/social/ui/components.tsx` | ageOf, msgLine, FacetTags, dateRange, MsgPreview, CollabStat |
| 43 | 9 | 2 | 11 | 53 | 262 | `web/src/lib/interaction-context.ts` | byteSize, buildView, EMPTY_EXTRAS, JOURNEY_TAIL, ContextExtras, choiceFilters |
| 43 | 5 | 3 | 6 | 52 | 311 | `connectors/facebook/api/insights-sync.js` | postPk, endTime, graphId, pageIdOf, fbPostIdOf, upsertPost |
| 42 | 11 | 6 | 16 | 61 | 124 | `server/shared/tenancy.js` | warnMissing, groupTenants, tenantContext, creationTenant, FOUNDING_TENANT |
| 41 | 15 | 44 | 38 | 104 | 92 | `server/shared/db.js` | loadEnv, withWrite, savepointSeq |
| 41 | 13 | 2 | 13 | 41 | 282 | `spheres/coord/api/read.js` | IN_SCOPE, listTasks, listSpaces, SCOPE_JOIN, taskSource, syncStatus |
| 40 | 11 | 2 | 13 | 47 | 108 | `server/shared/job-claims.js` | ttlMinutes, job-claims, intervalMinutes, sweepExpiredClaims |
| 38 | 16 | 3 | 19 | 45 | 319 | `web/src/pipeline/ContactPanel.tsx` | eventDate, NoteEditor, afterWrite, memberStage, ContactPanel, stageGuidance |
| 38 | 8 | 1 | 8 | 38 | 421 | `web/src/app/App.tsx` | resetKey, accessIcon, NoSuchPage, queryClient, settingsIcon, PaneBoundary |
| 38 | 6 | 2 | 8 | 51 | 104 | `spheres/library/ui/SearchBar.tsx` | setText, SearchBar, SETTLE_MS, useAnyReach, useQueryParam, useSelectedSources |
| 37 | 8 | 4 | 12 | 55 | 152 | `spheres/social/ui/cards.tsx` | onFunnel, inCampaign, campaignNames, openMenuItems |
| 37 | 4 | 3 | 6 | 56 | 376 | `connectors/sonas/api/sonas-client.js` | WS_URL, ejsonDate, ejsonToMysql, sonas-client, EPOCH_2100_MS, EPOCH_1900_MS |
| 35 | 6 | 2 | 8 | 47 | 76 | `connectors/awsconnect/api/sigv4.js` | sigv4, rfc3986, amzDate, datestamp, sha256hex, signingKey |
| 35 | 1 | 1 | 2 | 70 | 153 | `spheres/coord/api/decode.js` | decodeTask, lastAtName, lifecycleOf, messageName, ASSIGN_VERBS, spaceOfMessage |
| 34 | 8 | 4 | 12 | 51 | 68 | `server/shared/runbook.js` | loadRunbook, jobCodeLower, extractPrompt, resolveRunbook |
| 34 | 2 | 1 | 3 | 51 | 241 | `spheres/coord/api/meetings.js` | getMeeting, clampLimit, likeFragment, getTranscript, searchMeetings, addressMeeting |
| 33 | 27 | 2 | 29 | 35 | 26 | `web/src/lib/use-anchor.ts` | useAnchor, use-anchor |
| 33 | 17 | 1 | 18 | 35 | 11 | `server/shared/click-log.js` | click-log, recordClick |
| 33 | 7 | 1 | 8 | 38 | 132 | `web/src/lib/tool-labels.ts` | tool-labels, activityLine, LABELLED_TOOLS |
| 33 | 3 | 2 | 5 | 55 | 183 | `connectors/googlereviews/api/upsert.js` | rawCols, dataIds, placeSQL, placeRow, reviewRow, ownerCols |
| 33 | 1 | 1 | 2 | 66 | 286 | `spheres/relationships/api/identity.js` | personId, igHandle, sparKeys, normName, sonasKeys, normEmail |
| 32 | 2 | 2 | 4 | 64 | 165 | `spheres/schedule/api/reconcile-logic.js` | agedOut, targetOf, listOpenMoves, matchesTarget, decidePending, parseNativeId |
| 32 | 3 | 1 | 4 | 43 | 154 | `server/shared/contract.js` | isFunc, isString, jobProblems, validateOwnerConfig, reservedNameProblem, RESERVED_SHELL_NAMES |
| 32 | 1 | 1 | 2 | 65 | 215 | `connectors/spar/api/upsert.js` | pkCount, clipRow, segRows, valueRows, passStart, upsertRows |
| 30 | 11 | 13 | 11 | 30 | 384 | `connectors/awsconnect/api/sync.js` | venueTz, listKey, listAll, syncCost, windowMs, syncUsers |
| 30 | 6 | 1 | 7 | 35 | 356 | `connectors/rezdy/api/upsert.js` | categoryId, voucherCode, localToMysql, storedLocalText, captureBookingChanges, upsertCategoryProducts |
| 30 | 2 | 2 | 3 | 45 | 296 | `spheres/schedule/api/almanac.js` | termRow, optDate, optText, MONTH_RE, entryRow, FILE_SQL |
| 29 | 4 | 5 | 9 | 66 | 146 | `spheres/financial/ui/period.ts` | fyStart, extendTo, monthsOf, shortMonth, orderRange, monthLabel |
| 29 | 7 | 1 | 8 | 33 | 119 | `server/shared/connector-health.js` | RUN_STRIP, healthRows, recentRuns, HEALTH_KINDS, HEALTH_REASONS, connector-health |
| 28 | 12 | 3 | 15 | 35 | 23 | `web/src/ui/FilterRow.tsx` | FilterRow |
| 28 | 8 | 1 | 9 | 32 | 1113 | `spheres/projects/ui/views/Gantt.tsx` | Gantt, MsPanel, onWrite, chainOf, SEC_HEAD, todayUTC |
| 27 | 5 | 5 | 8 | 43 | 82 | `spheres/library/ui/api.ts` | HitKind, sourceOf, SourceId, SearchKind, ItemResponse, ProviderError |
| 26 | 3 | 2 | 5 | 43 | 254 | `web/src/lib/chat.ts` | onTool, onError, onDrive, ChatSend, sendChat, probeChat |
| 26 | 3 | 1 | 4 | 34 | 222 | `web/src/lib/chat-store.ts` | headId, isRecord, setChatId, chat-store, chatThread, saveRecord |
| 26 | 2 | 1 | 3 | 39 | 87 | `server/shared/closure.js` | rowFor, libRefs, notFound, storeDir, findTypeB, artifactRef |
| 25 | 10 | 1 | 11 | 28 | 86 | `web/src/app/ChatPane.tsx` | ChatPane, ChatUnreachable |
| 25 | 6 | 3 | 9 | 38 | 72 | `server/shared/datasets.js` | knownDataset, servedDatasets |
| 25 | 5 | 2 | 7 | 35 | 39 | `web/src/app/chat-handle.tsx` | ChatHandle, chat-handle |
| 25 | 6 | 0 | 6 | 25 | 372 | `spheres/social/api/bi01.test.js` | OWN_LONG, inboxPage, aRealPair, OWN_SHORT, bi01.test, igThreadId |
| 25 | 4 | 3 | 4 | 25 | 85 | `spheres/schedule/api/config.js` | isPosInt, validateConfig |
| 25 | 2 | 4 | 2 | 25 | 157 | `spheres/schedule/api/providers/sonas.js` | headcount, WEDDINGS_SQL, utcSqlString, VENUE_TZ_SQL, mapWeddingRow, WEDDING_STATUS |
| 24 | 5 | 9 | 14 | 66 | 213 | `web/src/lib/error-codes.ts` | ErrorCode, errorText, localizeParams |
| 24 | 5 | 9 | 11 | 52 | 105 | `spheres/financial/ui/api.ts` | PLRow, exGst, PLSource, prevExGst, LabourRow, ProductRow |
| 24 | 10 | 1 | 11 | 26 | 37 | `agent/system-prompt.js` | systemPrompt, system-prompt |
| 23 | 8 | 2 | 10 | 29 | 198 | `web/src/pipeline/StagesEditor.tsx` | StageRow, onRemove, StagesEditor |
| 23 | 7 | 1 | 8 | 26 | 163 | `agent/drive-tools.js` | driveSeq, driveTool, driveTools, DRIVE_CODES, drive-tools, resolveDrive |
| 22 | 4 | 6 | 10 | 54 | 64 | `server/shared/venue-date.js` | fmtDay, venueDate, venue-date, epochSeconds |
| 22 | 8 | 2 | 10 | 27 | 51 | `server/shared/ollama.js` | ollama, runRunbookLocal |
| 22 | 5 | 1 | 6 | 27 | 74 | `spheres/schedule/ui/ConfirmMove.tsx` | onConfirm, ConfirmMove |
| 22 | 5 | 1 | 6 | 26 | 156 | `connectors/rezdy/api/rezdy-client.js` | payloadOf, rezdy-client, makeRezdyClient |
| 22 | 3 | 1 | 4 | 30 | 112 | `spheres/schedule/api/moves.js` | OPEN_SQL, CANCEL_SQL, cancelMove, INSERT_SQL, requestMove, RESOLVE_SQL |
| 22 | 2 | 1 | 3 | 33 | 101 | `spheres/reputation/ui/lanes.ts` | LaneKpi, overTarget, deriveLanes, responseDays, negativeFirst, repliedWindowDays |
| 22 | 1 | 1 | 2 | 45 | 315 | `connectors/spar/api/parse.js` | dateN, tsvText, asGiven, fileStem, needsFix, indentOf |
| 21 | 11 | 1 | 12 | 23 | 39 | `web/src/ui/SearchInput.tsx` | autoFocus, SearchInput |
| 19 | 2 | 1 | 2 | 19 | 299 | `spheres/coord/ui/views/Meetings.tsx` | monthKey, setPages, setAfter, groupByMonth, PERSON_CHIPS, MeetingDetail |
| 18 | 8 | 1 | 9 | 20 | 399 | `spheres/coord/api/jobs-a.js` | jobs-a, entityRows, buildMeetingJobs |
| 18 | 3 | 1 | 3 | 18 | 904 | `spheres/financial/api/read.js` | putCell, rentRow, SEG_CAT, rezdyRows, sonasRows, sectionOf |
| 18 | 2 | 1 | 3 | 27 | 642 | `spheres/social/api/performance.js` | fbType, igType, ownPks, fbPosts, igPosts, monthOf |
| 18 | 1 | 2 | 1 | 18 | 274 | `connectors/otter/api/jobs.js` | ACCOUNT_ID, UPSERT_CHUNK, validateList, recordingRow, validateFetch, UPSERT_RECORDINGS_SQL |
| 17 | 6 | 2 | 8 | 23 | 96 | `spheres/publicity/ui/CoverageSection.tsx` | onAdded, coverageBadge, coverageSection, CoverageSection |
| 17 | 4 | 2 | 6 | 25 | 113 | `spheres/reputation/ui/ReviewCard.tsx` | isLong, ClampText, showPlace, reviewsUrl, ReviewCard, CLAMP_CHARS |
| 17 | 4 | 2 | 6 | 26 | 166 | `server/shared/manifest.js` | skillsRoot, loadManifest, REQUIRED_KEYS, manifestPaths, validateManifest, scanManifestPaths |
| 16 | 9 | 3 | 11 | 20 | 103 | `web/src/lib/org-identity.ts` | TaxRegister, org-identity, TAX_REGISTERS, taxRegisterFor, LetterheadLines, OrgIdentityFields |
| 16 | 5 | 4 | 9 | 29 | 118 | `server/shared/stage-vocabulary.js` | subsetAllows, stage-vocabulary, buildStageVocabulary |
| 16 | 3 | 3 | 6 | 32 | 186 | `web/src/lib/locale.ts` | regionIn, formatLocale, ES_419_REGIONS, activateLocale, ZH_HANT_REGIONS, ZH_HANS_REGIONS |
| 16 | 3 | 2 | 5 | 27 | 77 | `server/shared/credential-manifests.js` | manifestFor, DEFAULT_ROOT, listManifests, credential-manifests |
| 16 | 3 | 2 | 5 | 27 | 45 | `server/shared/trail.js` | recordWrite |
| 16 | 2 | 3 | 5 | 41 | 408 | `server/shared/sql-static.js` | sqlRaw, cleanIdent, sql-static, matchParen, parseSchema, parseWrites |
| 16 | 5 | 0 | 5 | 16 | 318 | `server/shared/grants.test.js` | grants.test, COVERS_VECTORS, ALLOWED_VECTORS, VERB_COVER_VECTORS, TOKEN_COVER_VECTORS |
| 15 | 6 | 3 | 9 | 23 | 192 | `spheres/financial/ui/PeriodPicker.tsx` | atDefault, PeriodPicker |
| 15 | 4 | 1 | 5 | 19 | 268 | `web/src/lib/assistant-runtime.ts` | onChatId, ackedSeq, frameQueue, lastUserText, restoreChatId, ChatAdapterHandle |
| 15 | 5 | 1 | 5 | 15 | 652 | `spheres/projects/api/read.js` | slugOk, badSlug, livesAt, postLink, parseRefs, projectId |
| 15 | 1 | 1 | 1 | 15 | 1026 | `spheres/social/ui/PerformanceSection.tsx` | SortTh, onSort, labelOf, DeltaChip, FIRST_SLICE, genderLabel |
| 14 | 5 | 1 | 5 | 14 | 164 | `spheres/schedule/ui/views/Pending.tsx` | MoveRow, canWrite |
| 14 | 1 | 4 | 5 | 68 | 41 | `server/shared/contract-helpers.js` | faultReason, callerMetaUrl, contractReason, compileContract, contract-helpers |
| 14 | 3 | 2 | 5 | 24 | 86 | `server/shared/pipeline-fixture.js` | viewBody, VIEW_BODY, platformSql, tempTableDdl, statementFrom, setupPipelineCore |
| 14 | 1 | 1 | 2 | 28 | 333 | `connectors/xero/api/upsert.js` | mysqlDt, LINE_SQL, LINE_COLS, xeroDateMs, TRACKING_SQL, paymentTarget |
| 13 | 10 | 0 | 10 | 13 | 82 | `server/shared/error-codes.test.js` | error-codes.test |
| 13 | 7 | 1 | 8 | 15 | 105 | `connectors/googlereviews/api/import-historical.js` | runImport, import-historical |
| 13 | 2 | 6 | 7 | 47 | 83 | `web/src/lib/grants.ts` | AuthReach, GrantVerb, GrantToken |
| 13 | 3 | 5 | 7 | 30 | 323 | `server/shared/stage-advance.js` | sqlDate, FLIP_UTC, frameLook, envPrefix, STAGE_GUARD, graceMinutesFor |
| 13 | 1 | 1 | 1 | 13 | 134 | `connectors/deputy/api/upsert.js` | dateOnly, epochToMysql |
| 12 | 7 | 2 | 9 | 16 | 43 | `server/shared/secret-box.js` | IV_LEN, TAG_LEN, plaintext, secret-box |
| 12 | 4 | 1 | 5 | 15 | 135 | `connectors/deputy/api/deputy-client.js` | deputy-client, makeDeputyClient |
| 12 | 2 | 2 | 4 | 24 | 67 | `spheres/social/ui/CampaignDelete.tsx` | onDeleted, CampaignDelete, CampaignDeleteButton |
| 12 | 3 | 1 | 4 | 16 | 70 | `connectors/googlereviews/api/serpapi-client.js` | SEARCH_URL, serpapi-client, makeSerpapiClient |
| 12 | 1 | 3 | 4 | 50 | 343 | `connectors/onedrive/api/graph-client.js` | pathOf, postGrant, searchUrl, GRAPH_BASE, filterKind, driveOwner |
| 12 | 3 | 1 | 3 | 12 | 818 | `spheres/social/ui/ContactDetail.tsx` | onPick, PostRow, onJoined, shortTime, onRemoved, mediaLabel |
| 11 | 7 | 0 | 7 | 11 | 263 | `agent/agreement.test.js` | pathParams, derivedNames, agreement.test |
| 11 | 4 | 3 | 5 | 14 | 252 | `spheres/social/api/stage-advance.js` | PK_OF, entryPass, CAMPAIGN_OF, entryPassDue, HAS_NEW_OUTBOUND, HAS_INBOUND_TEXT |
| 11 | 2 | 1 | 3 | 17 | 134 | `spheres/coord/ui/views/MeetingFollowUp.tsx` | meetingPath, spaceRoomUrl, composeFollowUp, MeetingFollowUp |
| 11 | 2 | 1 | 3 | 17 | 181 | `connectors/tiktok/api/insights-sync.js` | openId, videoRow, unixToVenue, unixSeconds, upsertVideo, loadTokenFile |
| 11 | 2 | 1 | 3 | 17 | 85 | `server/shared/chat.js` | toolRoutes, handleChat |
| 11 | 1 | 1 | 1 | 11 | 260 | `web/src/pipeline/CampaignBoard.tsx` | boardColumns, strayColumns, offFunnelColumns |
| 11 | 1 | 0 | 1 | 11 | 199 | `spheres/customer-service/api/calls.test.js` | TZ_ROW, totalsRow, calls.test |
| 10 | 7 | 0 | 7 | 10 | 2080 | `server/shared/auth.test.js` | adminReq, usersApi, wallState, APPS_RUNS, auth.test, roleState |
| 10 | 3 | 3 | 6 | 20 | 359 | `connectors/dropbox/api/dropbox-client.js` | API_BASE, EXT_KIND, HOME_URL, homeLink, matchMeta, parentPath |
| 10 | 3 | 1 | 4 | 14 | 137 | `connectors/clover/api/clover-client.js` | elementsOf, clover-client, makeCloverClient |
| 10 | 3 | 0 | 3 | 10 | 447 | `server/shared/credentials.test.js` | hookFor, staleRow, tenantRows |
| 10 | 1 | 1 | 2 | 20 | 46 | `spheres/financial/ui/window.ts` | filterRows, OptionalSource, OPTIONAL_SOURCES |
| 10 | 2 | 1 | 2 | 10 | 240 | `connectors/deputy/api/sync.js` | maxId, maxMs, floorSec, sinceText, syncIncremental |
| 10 | 1 | 1 | 2 | 20 | 228 | `spheres/coord/api/jobs.js` | threadKey, replayLifecycle, reconstructTasks, LIFECYCLE_STATUS |
| 9 | 3 | 6 | 9 | 26 | 29 | `web/src/lib/use-pathname.ts` | usePathname, use-pathname |
| 9 | 5 | 1 | 5 | 9 | 1491 | `spheres/social/api/read.js` | ownPk, isMember, draftRow, actorFor, unreadFor, unpackMsg |
| 9 | 3 | 1 | 4 | 12 | 499 | `web/src/app/AccessRoles.tsx` | onSet, SegRow, roleCell, CellPair, CellTone, RoleDrawer |
| 9 | 3 | 1 | 4 | 12 | 156 | `connectors/github/api/github-client.js` | USER_AGENT, encodePath, API_VERSION, resetWaitMs, github-client, isRateLimited |
| 9 | 3 | 1 | 4 | 12 | 14 | `server/shared/model-api.js` | model-api, runRunbookApi |
| 9 | 2 | 0 | 2 | 9 | 433 | `web/src/app/ChatAssistant.tsx` | DOCK_KEY, UserText, dockIcon, ToolLine, floatIcon, PanelMode |
| 9 | 1 | 1 | 1 | 9 | 452 | `spheres/financial/ui/views/ProfitAndLoss.tsx` | NetRow, segCount, parseSrc, monthNets, dashBelow, serializeSrc |
| 9 | 1 | 1 | 1 | 9 | 99 | `spheres/library/api/read.js` | itemRoute, defaultLog, searchRoute, buildHandleApi |
| 9 | 1 | 0 | 1 | 9 | 80 | `spheres/schedule/reconcile.js` | CLOSE_SQL, STALE_SQL, reconcilePass |
| 8 | 4 | 1 | 5 | 10 | 65 | `web/src/lib/chat-starters.ts` | BY_SPHERE, chat-starters, STARTER_SPHERES |
| 8 | 5 | 0 | 5 | 8 | 1352 | `server/app.js` | _mods, readGate, relToRepo, checkAuth, adminOnly, _hookSweep |
| 8 | 3 | 0 | 3 | 8 | 175 | `connectors/spar/sync.js` | readText, listFiles |
| 8 | 1 | 1 | 2 | 15 | 90 | `spheres/customer-service/api/transcripts.js` | transcribeCall, readTranscript |
| 8 | 2 | 1 | 2 | 8 | 335 | `spheres/schedule/api/read.js` | metaRoute, slotsRoute, ghostEntry, rangeRoute, upsertEntry, mergePending |
| 8 | 1 | 1 | 2 | 15 | 31 | `server/shared/versions.js` | latestRow, commitSha, decideAppend |
| 8 | 1 | 1 | 1 | 8 | 605 | `spheres/social/ui/CampaignBoard.tsx` | onReview, DraftChip, MemberCard |
| 8 | 1 | 1 | 1 | 8 | 219 | `server/shared/access.js` | routeOf, missingRefs, emptyAnswer |
| 7 | 3 | 1 | 4 | 9 | 132 | `connectors/awsconnect/api/aws-client.js` | aws-client, makeAwsClient |
| 7 | 1 | 1 | 2 | 14 | 285 | `web/src/lib/drive.ts` | slotOf, DriveView, driveSplit, DriveEvent, driveFilter, surfaceView |
| 7 | 2 | 1 | 2 | 7 | 214 | `connectors/clover/api/upsert.js` | lineMods, sumCents, lineTaxes, msToLocal, lineDiscounts |
| 6 | 2 | 11 | 13 | 40 | 27 | `web/src/lib/view-scope.ts` | useSlot, ViewScope, view-scope |
| 6 | 6 | 0 | 6 | 6 | 454 | `server/shared/party.test.js` | CLAIM_ROW, party.test |
| 6 | 6 | 0 | 6 | 6 | 250 | `server/shared/tenant-conformance.test.js` | GROUP_TABLES, OWNER_COLUMNS, NO_TENANT_SCHEMA, PLATFORM_PIPELINE, tenant-conformance.test |
| 6 | 4 | 1 | 5 | 7 | 119 | `connectors/googlechat/api/chat-client.js` | chat-client, makeChatClient |
| 6 | 2 | 2 | 4 | 12 | 31 | `spheres/coord/capture.js` | doneSignal, CAPTURE_REPO, OTHER_BUSINESS_PREFIX |
| 6 | 3 | 1 | 4 | 8 | 110 | `spheres/publicity/api/jobs.js` | memberFromId, buildPublicityJobs |
| 6 | 4 | 0 | 4 | 6 | 93 | `scripts/deploy-skills.mjs` | arefs, isSkillRef, deploy-skills |
| 6 | 3 | 1 | 3 | 6 | 232 | `connectors/googlereviews/api/sync.js` | isoDate, markRun, reviewId, syncPlace, loadPlaces, searchesLast30d |
| 6 | 1 | 2 | 3 | 18 | 52 | `server/shared/deepseek.js` | deepseek, MODEL_ID, runRunbookDeepseek |
| 6 | 1 | 1 | 2 | 12 | 457 | `spheres/customer-service/api/calls.js` | daysOf, heatOf, costOf, repsOf, repName, todayIn |
| 6 | 1 | 1 | 1 | 6 | 125 | `spheres/customer-service/api/read.js` | DAYS_MAX, CAL_DATE, callsParams |
| 6 | 1 | 1 | 1 | 6 | 57 | `server/shared/events.js` | createDoorbell |
| 5 | 1 | 6 | 6 | 29 | 38 | `web/src/app/match.ts` | activeNav, atAppRoot, activeSphere |
| 5 | 5 | 0 | 5 | 5 | 132 | `server/shared/tenant-registry.test.js` | withRegistry, FOUNDING_TENANTS, tenant-registry.test |
| 5 | 5 | 0 | 5 | 5 | 142 | `scripts/stage-flip-harness.mjs` | stage-flip-harness |
| 5 | 4 | 1 | 4 | 5 | 321 | `spheres/relationships/ui/views/Matches.tsx` | QueueRow, memberId, RowMember, buildRows, sourceLabel, evidenceLabel |
| 5 | 4 | 0 | 4 | 5 | 122 | `server/shared/manifest.test.js` | manifest.test |
| 5 | 4 | 0 | 4 | 5 | 66 | `server/shared/route-manifest.test.js` | route-manifest.test |
| 5 | 1 | 2 | 3 | 15 | 45 | `web/src/app/access-sections.ts` | AccessSection, accessSection, ACCESS_SECTIONS, access-sections, accessSectionFor, accessSectionsFor |
| 5 | 1 | 2 | 3 | 15 | 40 | `spheres/coord/ui/windows.tsx` | isWindow, WindowChips, useWindowParam |
| 5 | 2 | 1 | 3 | 8 | 50 | `server/shared/http-json.js` | http-json |
| 5 | 1 | 1 | 2 | 10 | 30 | `spheres/schedule/ui/slots.tsx` | slotZones |
| 5 | 1 | 1 | 1 | 5 | 304 | `connectors/googlechat/api/sync.js` | nowIso, floorIso, syncSpace, dumpSpaces, persistPage, upsertSpaces |
| 5 | 1 | 1 | 1 | 5 | 137 | `connectors/square/api/upsert.js` | isoToLocal |
| 5 | 1 | 0 | 1 | 5 | 153 | `spheres/financial/api/walls.test.js` | WAGE_CODE, seedLedger, sourceType, seedJournal, admitToWages |
| 5 | 1 | 1 | 1 | 5 | 115 | `spheres/publicity/api/read.js` | buildApi, coverageList, coverageCounts |
| 4 | 2 | 18 | 20 | 35 | 54 | `server/shared/http-raw.js` | http-raw |
| 4 | 4 | 3 | 5 | 5 | 159 | `web/src/pipeline/Roster.tsx` | isDue, rowBadges |
| 4 | 4 | 0 | 4 | 4 | 142 | `server/shared/invariants.test.js` | isTest, invariants.test, FOUNDING_SLUG_HOMES |
| 4 | 4 | 0 | 4 | 4 | 110 | `server/shared/schema-conformance.test.js` | schema-conformance.test |
| 4 | 1 | 2 | 3 | 13 | 68 | `spheres/financial/ui/vocab.ts` | LocalName, localNameIn, VOCAB_ROUTE, useLocalName, SOURCE_LOCALE |
| 4 | 1 | 2 | 3 | 12 | 34 | `connectors/awsconnect/api/presign.js` | presign, presignS3Get |
| 4 | 1 | 1 | 2 | 7 | 59 | `web/src/ui/highlight.ts` | highlightAnchor |
| 4 | 1 | 1 | 2 | 8 | 459 | `web/src/app/AccessApps.tsx` | FieldRow, RunBlock, reasonText, AccessApps, SessionRow, PRODUCT_NAME |
| 4 | 1 | 1 | 2 | 9 | 334 | `spheres/relationships/ui/views/PersonPanel.tsx` | onGone, PersonPanel, ProfileStats |
| 4 | 1 | 1 | 2 | 9 | 115 | `spheres/schedule/ui/EntryEditor.tsx` | EntryEditor |
| 4 | 1 | 1 | 1 | 4 | 36 | `spheres/customer-service/api/policy.js` | loadPolicy |
| 3 | 2 | 1 | 3 | 5 | 29 | `web/src/lib/useDoorbell.ts` | useDoorbell |
| 3 | 3 | 0 | 3 | 3 | 296 | `web/src/lib/interaction-context.test.ts` | interaction-context.test |
| 3 | 3 | 0 | 3 | 3 | 169 | `connectors/otter/api/bo01.test.js` | bo01.test |
| 3 | 3 | 0 | 3 | 3 | 58 | `spheres/coord/api/instance.js` | prelinkDue, reconstructDue |
| 3 | 3 | 0 | 3 | 3 | 230 | `spheres/coord/api/meetings.test.js` | responder, meetings.test |
| 3 | 2 | 1 | 3 | 4 | 725 | `spheres/social/api/jobs.js` | GATE_BATCH, buildCrmJobs, anyMarketing, CLEAN_HEALTH, threadMembers, truncateLines |
| 3 | 1 | 1 | 2 | 6 | 42 | `web/src/lib/gesture-state.ts` | gesture-state, useGestureState |
| 3 | 1 | 1 | 2 | 6 | 17 | `web/src/lib/download.ts` | saveBlob |
| 3 | 2 | 2 | 2 | 3 | 196 | `spheres/coord/ui/views/ByPerson.tsx` | TaskSource, PersonTasks |
| 3 | 1 | 1 | 2 | 6 | 108 | `connectors/square/api/square-client.js` | square-client, SQUARE_VERSION, makeSquareClient |
| 3 | 2 | 0 | 2 | 3 | 426 | `spheres/schedule/api/providers.test.js` | providers.test |
| 3 | 2 | 1 | 2 | 3 | 424 | `server/shared/party.js` | claimKey, postClaim, liveClaims, jsonEmails, postRetire, listParties |
| 3 | 2 | 0 | 2 | 3 | 134 | `server/shared/connector-tenant.test.js` | withAttribution, connector-tenant.test |
| 3 | 1 | 0 | 1 | 3 | 74 | `spheres/coord/prelink.js` | prelinkMeetings |
| 3 | 1 | 0 | 1 | 3 | 237 | `spheres/social/api/jobsdesc.test.js` | T_BI03, T_SOLO, T_AI01, T_GROUP, addMember, CONTACT_A |
| 2 | 1 | 3 | 4 | 9 | 134 | `connectors/tiktok/api/tiktok-client.js` | API_HOST, tokenCall, AUTH_HOST, USER_FIELDS, VIDEO_FIELDS, tiktok-client |
| 2 | 1 | 2 | 3 | 5 | 32 | `web/src/lib/overseer.ts` | probeOverseer, overseerSecret |
| 2 | 1 | 1 | 2 | 4 | 513 | `web/src/app/AccessPeople.tsx` | InviteRow, AccessPeople, effectiveAccess |
| 2 | 1 | 1 | 2 | 4 | 249 | `web/src/app/AccessWalls.tsx` | WallCard, AccessWalls |
| 2 | 1 | 1 | 2 | 5 | 206 | `spheres/social/ui/drafts.tsx` | onPatch, DraftDrawer |
| 2 | 1 | 1 | 2 | 4 | 370 | `spheres/social/ui/CampaignWizard.tsx` | CampaignWizard |
| 2 | 1 | 1 | 2 | 4 | 82 | `spheres/social/ui/useAutoSweep.ts` | SWEEP_MS, LAST_KEY, useAutoSweep, stampDispatch, lastDispatchAt |
| 2 | 1 | 1 | 2 | 4 | 34 | `spheres/financial/api/policy.js` | dealsClaims, frozenClaims, claimedDealsCampaigns |
| 2 | 2 | 0 | 2 | 2 | 444 | `server/shared/spar-pipeline.test.js` | STAGE_GATE, spar-pipeline.test |
| 2 | 2 | 0 | 2 | 2 | 126 | `agent/descriptions.test.js` | WORD_CEILING, descriptions.test, EXCEPTION_CEILING |
| 2 | 2 | 0 | 2 | 2 | 561 | `agent/server.js` | TLS_KEY, newTurn, TLS_CERT, BODY_CAP, logDetail, toolWiring |
| 2 | 2 | 0 | 2 | 2 | 549 | `agent/server.test.js` | signJwt, toolUse, extraEnv, ORIGIN_A, bootFeed, ORIGIN_B |
| 2 | 2 | 0 | 2 | 2 | 151 | `scripts/import-meta-exports.test.mjs` | import-meta-exports.test |
| 2 | 1 | 1 | 1 | 2 | 761 | `spheres/customer-service/ui/views/Calls.tsx` | hadOne, foldDays, sliceFor, LOG_SLICE, foldRepDays, TenantBlock |
| 2 | 1 | 0 | 1 | 2 | 321 | `connectors/spar/api/parse.test.js` | ROW_B, ROW_A, ROW_C, HEADER_A, HEADER_B, parse.test |
| 2 | 1 | 0 | 1 | 2 | 158 | `spheres/social/api/ai00.test.js` | T_NON, T_MKT, T_MISS, ai00.test, batchPersist, seedAccounts |
| 2 | 1 | 0 | 1 | 2 | 150 | `server/shared/walls.test.js` | seedWall, emptyConn, missingConn |
| 1 | 1 | 7 | 8 | 9 | 19 | `server/shared/db-errors.js` | db-errors |
| 1 | 1 | 0 | 1 | 1 | 52 | `connectors/awsconnect/api/sigv4.test.js` | sigv4.test |
| 1 | 1 | 1 | 1 | 1 | 214 | `connectors/clover/api/sync.js` | syncOrders, watermarkMs, localZoneOf |
| 1 | 1 | 0 | 1 | 1 | 141 | `connectors/otter/api/bo02.test.js` | bo02.test, seededConn |
| 1 | 1 | 0 | 1 | 1 | 246 | `spheres/schedule/api/moves.test.js` | goodBody, moves.test, localHandlers |
| 1 | 1 | 0 | 1 | 1 | 432 | `spheres/social/api/bi03.test.js` | bi03.test, postsPage, liveMember, seedApprovedThread, seedMultiMemberThread, seedRestedMarketingThread |
| 1 | 1 | 0 | 1 | 1 | 71 | `spheres/social/api/jobrun-version.test.js` | jobrun-version.test |
| 1 | 1 | 0 | 1 | 1 | 105 | `server/shared/closure.test.js` | makeStore, publicRow, closure.test |
| 1 | 1 | 0 | 1 | 1 | 142 | `server/shared/connector-health.test.js` | connector-health.test |
| 1 | 1 | 0 | 1 | 1 | 430 | `server/shared/dispatch.test.js` | trailConn, personWith, dispatch.test |
| 1 | 1 | 0 | 1 | 1 | 144 | `server/shared/job-runs.test.js` | fakeDeps, RUN_BASE, job-runs.test |
| 1 | 1 | 0 | 1 | 1 | 408 | `server/shared/sync-runs.test.js` | gateConn, makeFakeDb, sync-runs.test, makeFrameHarness |
| 1 | 1 | 0 | 1 | 1 | 49 | `server/shared/versions.test.js` | versions.test |
| 1 | 1 | 0 | 1 | 1 | 103 | `scripts/import-env-credentials.mjs` | import-env-credentials |
| 0 | 0 | 4 | 4 | 21 | 30 | `spheres/schedule/api/valid.js` | isHHMM, DATE_RE, HHMM_RE, spanDays, isISODate |
| 0 | 0 | 3 | 3 | 14 | 66 | `spheres/financial/ui/letterhead.ts` | useTenants, TenantInfo, soleCountry, letterheadFor |
| 0 | 0 | 3 | 3 | 12 | 260 | `spheres/library/ui/Results.tsx` | fmtSize, KindGlyph, kindLabel, MediaGrid, reachLabel, SourceGroup |
| 0 | 0 | 3 | 3 | 8 | 94 | `spheres/schedule/ui/cards.tsx` | timeFace, shortDate, EntryCard, PeopleGlyph |
| 0 | 0 | 2 | 2 | 18 | 226 | `web/src/app/AccessGrants.tsx` | refOf, ownToken, GrantCell, roleCover, VerbState, cellVerbs |
| 0 | 0 | 2 | 2 | 6 | 91 | `spheres/library/ui/ItemOverlay.tsx` | ItemOverlay |
| 0 | 0 | 2 | 2 | 10 | 30 | `spheres/reputation/ui/PlaceChips.tsx` | PlaceChips, usePlaceParam |
| 0 | 0 | 2 | 2 | 4 | 20 | `spheres/social/ui/sweep.ts` | dispatchSweep |
| 0 | 0 | 2 | 2 | 8 | 44 | `server/shared/model-retry.js` | model-retry, sendWithRetry, FIVEXX_BACKOFF_MS |
| 0 | 0 | 18 | 1 | 2 | 33 | `web/src/app/sphere.ts` | NavItem |
| 0 | 0 | 1 | 1 | 4 | 9 | `web/src/app/chat-icon.tsx` | chatIcon, chat-icon |
| 0 | 0 | 1 | 1 | 3 | 242 | `web/src/app/AccessTenants.tsx` | OrgRow, OrgDrawer, AccessTenants |
| 0 | 0 | 1 | 1 | 3 | 76 | `spheres/social/ui/useUnreadNotifier.ts` | useUnreadNotifier |
| 0 | 0 | 1 | 1 | 5 | 281 | `spheres/social/ui/PerformanceChart.tsx` | niceMax, useWidth, PerformanceChart |
| 0 | 0 | 1 | 1 | 11 | 115 | `spheres/projects/api/statements.js` | clearBall, updateBall, upsertLink, deleteLink, insertEvent, upsertProject |
| 0 | 0 | 2 | 1 | 2 | 36 | `spheres/social/api/statements.js` | insertSubset |
| 0 | 0 | 1 | 0 | 0 | 181 | `web/src/app/PrefsPanel.tsx` | DATE_SAMPLE |
| 0 | 0 | 1 | 0 | 0 | 10 | `web/src/vite-env.d.ts` | vite-env.d |
| 0 | 0 | 0 | 0 | 0 | 233 | `web/src/lib/view-slot.test.tsx` | view-slot.test |
| 0 | 0 | 3 | 0 | 0 | 144 | `web/src/pipeline/Campaigns.tsx` | CampaignCard |
| 0 | 0 | 1 | 0 | 0 | 141 | `spheres/coord/ui/views/Board.tsx` | columnOf |
| 0 | 0 | 1 | 0 | 0 | 276 | `spheres/financial/ui/views/Labour.tsx` | pctLabel, deltaLabel, hoursLabel, moneyOrDash, hoursOrDash |
| 0 | 0 | 1 | 0 | 0 | 199 | `spheres/financial/ui/views/Products.tsx` | MoveChip, CHANNEL_NAME |
| 0 | 0 | 1 | 0 | 0 | 169 | `spheres/projects/ui/views/Portfolio.tsx` | ProjectCard, PortfolioBoard |
| 0 | 0 | 1 | 0 | 0 | 233 | `spheres/relationships/ui/views/People.tsx` | handleOf, subtitleOf, stagePills, presenceMarks, SOURCE_OPTIONS |
| 0 | 0 | 1 | 0 | 0 | 306 | `spheres/schedule/ui/views/Week.tsx` | ISO_DAY, draftOf, parseWeek, rangeLabel, serializeWeek, PendingConfirm |
| 0 | 0 | 1 | 0 | 0 | 432 | `spheres/schedule/ui/views/Almanac.tsx` | dayOf, termTag, windowOf, termSpan, CAT_WORD, parseYear |
| 0 | 0 | 1 | 0 | 0 | 163 | `spheres/social/ui/CampaignsSection.tsx` | CampRoute, routeFromPath |
| 0 | 0 | 1 | 0 | 0 | 251 | `spheres/social/ui/PeopleSection.tsx` | parseOff, pkFromPath, parseQuery, parseCollab, desktopLike, STARS_CODEC |
| 0 | 0 | 0 | 0 | 0 | 86 | `connectors/awsconnect/api/client.test.js` | fakeSign, clientWith |
| 0 | 0 | 0 | 0 | 0 | 170 | `connectors/awsconnect/api/upsert.test.js` | contactFixture |
| 0 | 0 | 0 | 0 | 0 | 187 | `connectors/deputy/api/upsert.test.js` | unitFixture, rosterFixture, employeeFixture, timesheetFixture |
| 0 | 0 | 0 | 0 | 0 | 395 | `connectors/dropbox/api/dropbox-client.test.js` | tokenOk, makeConn, dropbox-client.test |
| 0 | 0 | 1 | 0 | 0 | 167 | `connectors/facebook/api/graph-client.js` | POST_FIELDS |
| 0 | 0 | 0 | 0 | 0 | 53 | `connectors/github/hook.js` | subscriptionCount |
| 0 | 0 | 1 | 0 | 0 | 131 | `connectors/github/api/sync.js` | loadShas, touchFile, upsertFile |
| 0 | 0 | 0 | 0 | 0 | 168 | `connectors/github/api/sync.test.js` | BAD_YAML, GOOD_YAML |
| 0 | 0 | 0 | 0 | 0 | 116 | `connectors/googlereviews/api/client.test.js` | fakeHttps |
| 0 | 0 | 0 | 0 | 0 | 273 | `connectors/googlereviews/api/sync.test.js` | provIds, serpReview |
| 0 | 0 | 0 | 0 | 0 | 216 | `connectors/googlereviews/api/upsert.test.js` | findSQL, placeFixture, reviewFixture, PLACE_SCHEMA_COLS, REVIEW_SCHEMA_COLS |
| 0 | 0 | 0 | 0 | 0 | 185 | `connectors/linkedin/api/memdb.js` | rowKey |
| 0 | 0 | 0 | 0 | 0 | 68 | `connectors/linkedin/api/bl00.test.js` | LIVE_URN, bl00.test |
| 0 | 0 | 0 | 0 | 0 | 70 | `connectors/linkedin/api/bl01.test.js` | bl01.test |
| 0 | 0 | 0 | 0 | 0 | 88 | `connectors/linkedin/api/bl02.test.js` | bl02.test, inboxEnvelope |
| 0 | 0 | 0 | 0 | 0 | 91 | `connectors/linkedin/api/bl03.test.js` | bl03.test |
| 0 | 0 | 0 | 0 | 0 | 81 | `connectors/linkedin/api/bl04.test.js` | seedEdges, bl04.test, profFixture, connFixture |
| 0 | 0 | 0 | 0 | 0 | 84 | `connectors/linkedin/api/bl05.test.js` | bl05.test |
| 0 | 0 | 0 | 0 | 0 | 434 | `connectors/onedrive/api/graph-client.test.js` | UNFACETED_AUDIO, graph-client.test |
| 0 | 0 | 0 | 0 | 0 | 187 | `connectors/otter/api/memdb.js` | COALESCE_COLS |
| 0 | 0 | 1 | 0 | 0 | 204 | `connectors/rezdy/api/sync.js` | syncPerCategory |
| 0 | 0 | 0 | 0 | 0 | 344 | `connectors/rezdy/api/upsert.test.js` | bookingFixture |
| 0 | 0 | 1 | 0 | 0 | 317 | `connectors/sonas/api/upsert.js` | captureEventChanges |
| 0 | 0 | 1 | 0 | 0 | 251 | `connectors/sonas/api/sync.js` | syncPub, syncTabular, syncTabularDetail |
| 0 | 0 | 0 | 0 | 0 | 264 | `connectors/sonas/api/client.test.js` | makeFakeWs, sonasServer |
| 0 | 0 | 0 | 0 | 0 | 325 | `connectors/sonas/api/upsert.test.js` | eventFixture, financialRecordFixture |
| 0 | 0 | 0 | 0 | 0 | 212 | `connectors/spar/api/upsert.test.js` | callFor, insertCols, approachRow, campaignRow |
| 0 | 0 | 0 | 0 | 0 | 84 | `connectors/tiktok/insights-sync.js` | TOKEN_FILE |
| 0 | 0 | 0 | 0 | 0 | 141 | `connectors/tiktok/api/credentials.test.js` | TIKTOK_ENV |
| 0 | 0 | 1 | 0 | 0 | 242 | `connectors/xero/api/sync.js` | syncSettings, OFFSET_CHUNK, syncPaginated, syncOffsetWalk, newWatermarkMs, setOffsetCursor |
| 0 | 0 | 0 | 0 | 0 | 327 | `connectors/xero/api/sync.test.js` | mkJournal, journalRange |
| 0 | 0 | 0 | 0 | 0 | 242 | `connectors/xero/api/upsert.test.js` | invoiceFixture, accountFixture, journalFixture, bankTransferFixture, bankTransactionFixture |
| 0 | 0 | 0 | 0 | 0 | 140 | `spheres/coord/api/decode.test.js` | chatMsg, taskMsg, decode.test, selfTaskMsg, completedMsg |
| 0 | 0 | 0 | 0 | 0 | 75 | `spheres/coord/api/instance.test.js` | prelinkHook, instance.test |
| 0 | 0 | 0 | 0 | 0 | 307 | `spheres/coord/api/jobs-a.test.js` | recRow, REC_TENANT, fullVerdict, jobs-a.test, derivedConn |
| 0 | 0 | 0 | 0 | 0 | 99 | `spheres/customer-service/api/read.test.js` | okPlan |
| 0 | 0 | 0 | 0 | 0 | 118 | `spheres/customer-service/api/transcripts.test.js` | transcripts.test |
| 0 | 0 | 0 | 0 | 0 | 212 | `spheres/financial/api/deals.test.js` | plainApi, deals.test |
| 0 | 0 | 0 | 0 | 0 | 652 | `spheres/financial/api/read.test.js` | SRC_FRAG, getVocab, fullPlan, ACCT_FRAG, labourPlan, VOCAB_ROWS |
| 0 | 0 | 1 | 0 | 0 | 50 | `spheres/library/api/providers.js` | appCreds |
| 0 | 0 | 0 | 0 | 0 | 164 | `spheres/library/api/read.test.js` | fakeRegistry |
| 0 | 0 | 0 | 0 | 0 | 302 | `spheres/partnership/api/read.test.js` | emptyApi |
| 0 | 0 | 0 | 0 | 0 | 162 | `spheres/projects/api/derive.test.js` | derive.test |
| 0 | 0 | 0 | 0 | 0 | 338 | `spheres/projects/api/read.test.js` | WRITE_ROUTES |
| 0 | 0 | 0 | 0 | 0 | 155 | `spheres/publicity/api/cursor.test.js` | seedMember, cursor.test |
| 0 | 0 | 0 | 0 | 0 | 116 | `spheres/publicity/api/look-claim.test.js` | HOOK_CLAIMS, look-claim.test |
| 0 | 0 | 1 | 0 | 0 | 670 | `spheres/relationships/api/read.js` | jsonStr, tripleKey, groupName, matchSide, personJson, buildPeople |
| 0 | 0 | 0 | 0 | 0 | 663 | `spheres/relationships/api/read.test.js` | withClaims |
| 0 | 0 | 1 | 0 | 0 | 174 | `spheres/reputation/api/read.js` | cleanText, listPlaces, listReviews, undismissReview |
| 0 | 0 | 0 | 0 | 0 | 51 | `spheres/reputation/api/dismiss-plural.test.js` | missingColumn, dismiss-plural.test |
| 0 | 0 | 0 | 0 | 0 | 168 | `spheres/reputation/api/read.test.js` | REVIEW_ROW |
| 0 | 0 | 0 | 0 | 0 | 450 | `spheres/schedule/api/almanac.test.js` | almanac.test |
| 0 | 0 | 0 | 0 | 0 | 104 | `spheres/schedule/api/config.test.js` | goodRaw, config.test |
| 0 | 0 | 0 | 0 | 0 | 43 | `spheres/schedule/api/instance.js` | reconcileDue |
| 0 | 0 | 0 | 0 | 0 | 464 | `spheres/schedule/api/read.test.js` | PENDING_NOW, pendingWindow, providerHandlers, withinPendingWeek |
| 0 | 0 | 0 | 0 | 0 | 231 | `spheres/schedule/api/reconcile-logic.test.js` | reconcile-logic.test |
| 0 | 0 | 0 | 0 | 0 | 203 | `spheres/schedule/api/reconcile.test.js` | dueConn, passConn, reconcile.test, CURRENT_BY_ORDER, CHANGES_BY_ORDER |
| 0 | 0 | 0 | 0 | 0 | 87 | `spheres/social/api/ai01.test.js` | ai01.test |
| 0 | 0 | 0 | 0 | 0 | 157 | `spheres/social/api/ai02.test.js` | NON_INFL, ai02.test, SMALL_INFL |
| 0 | 0 | 0 | 0 | 0 | 98 | `spheres/social/api/ai03.test.js` | ai03.test |
| 0 | 0 | 0 | 0 | 0 | 103 | `spheres/social/api/bi02.test.js` | bi02.test, threadPage |
| 0 | 0 | 0 | 0 | 0 | 233 | `spheres/social/api/contacts-filter.test.js` | seededPks, seedMatrix, nextThread, contacts-filter.test |
| 0 | 0 | 0 | 0 | 0 | 227 | `spheres/social/api/drafts.test.js` | drafts.test, makeCampaign, seedMarketingContact |
| 0 | 0 | 0 | 0 | 0 | 129 | `spheres/social/api/flip-subset.test.js` | gateRow, CAMP_ROW, IS_MEMBER, KNOWN_STAGE, flip-subset.test |
| 0 | 0 | 0 | 0 | 0 | 53 | `spheres/social/api/freshness.test.js` | A_STALE, A_FRESH, seedMarketingVisited |
| 0 | 0 | 0 | 0 | 0 | 362 | `spheres/social/api/performance.test.js` | MEDIA_B, MEDIA_A, FB_POST_ID, LONG_CAPTION, seedPerformance, performance.test |
| 0 | 0 | 0 | 0 | 0 | 1443 | `spheres/social/api/read.test.js` | seedUnreadThread |
| 0 | 0 | 0 | 0 | 0 | 142 | `spheres/social/api/stage-cursor.test.js` | stage-cursor.test |
| 0 | 0 | 0 | 0 | 0 | 81 | `server/shared/anthropic.test.js` | anthropic.test |
| 0 | 0 | 0 | 0 | 0 | 214 | `server/shared/chat.test.js` | DB_STUB, chat.test |
| 0 | 0 | 0 | 0 | 0 | 33 | `server/shared/click-log.test.js` | recordingConn, click-log.test |
| 0 | 0 | 0 | 0 | 0 | 200 | `server/shared/contract.test.js` | fakeSphere, fakeConnector |
| 0 | 0 | 0 | 0 | 0 | 80 | `server/shared/credential-manifests.test.js` | fixtureRoot, writeManifest, credential-manifests.test |
| 0 | 0 | 0 | 0 | 0 | 63 | `server/shared/deepseek.test.js` | deepseek.test |
| 0 | 0 | 0 | 0 | 0 | 68 | `server/shared/events.test.js` | eventsIn, fakeClient, events.test |
| 0 | 0 | 0 | 0 | 0 | 197 | `server/shared/job-claims.test.js` | fakeTable, job-claims.test |
| 0 | 0 | 0 | 0 | 0 | 50 | `server/shared/ollama.test.js` | ollama.test |
| 0 | 0 | 0 | 0 | 0 | 114 | `server/shared/ready.test.js` | ready.test, betaConfig, alphaConfig |
| 0 | 0 | 0 | 0 | 0 | 46 | `server/shared/runbook.test.js` | dirWith, runbook.test |
| 0 | 0 | 0 | 0 | 0 | 236 | `server/shared/spar-pipeline.walls.test.js` | ctxOf, spar-pipeline.walls.test |
| 0 | 0 | 0 | 0 | 0 | 146 | `server/shared/stage-advance.test.js` | viewRow |
| 0 | 0 | 0 | 0 | 0 | 139 | `server/shared/tenancy.test.js` | tenancy.test |
| 0 | 0 | 0 | 0 | 0 | 81 | `server/shared/trail.test.js` | trail.test |
| 0 | 0 | 0 | 0 | 0 | 67 | `server/shared/venue-date.test.js` | venue-date.test |
| 0 | 0 | 0 | 0 | 0 | 340 | `scripts/import-otter-corpus.test.js` | SCHEMA_FM, BROKEN_FM, import-otter-corpus.test |
