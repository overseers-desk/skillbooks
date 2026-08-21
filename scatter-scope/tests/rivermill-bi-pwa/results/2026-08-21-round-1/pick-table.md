# Pick table — modules

Expected is the median of three blind estimates. Gap is log3(measured / expected); outside +-1 is a flag.
Calibration for this run: A lands inside the band for 366 of 396 modules (median gap +0.00) and calibrates.
B lands inside for 221 of 396 (median gap -0.22) and has a long tail in both directions.
C is reported as density only (median gap +0.70; inside the band for 129 of 396).

| module | lines | A | A exp | gap A | B | B exp | gap B | C | C exp | leak | flag | furthest estimator | vocabulary sample |
|---|--:|--:|--:|--:|--:|--:|--:|--:|--:|--:|---|---|---|
| `server/shared/access.js` | 219 | 1 | 15 | -2.46 | 1 | 18 | -2.63 | 8 | 30 | 1 | A low, B low | e3 | routeOf, missingRefs, emptyAnswer |
| `spheres/schedule/api/providers/local.js` | 109 | 4 | 1 | +1.26 | 238 | 4 | +3.72 | 731 | 5 | 235 | A high, B high | e1 | local, toMin, shiftEnd, MOVE_SQL, getEntry |
| `server/shared/testdb.js` | 25 | 0 | 8 | -2.52 | 36 | 5 | +1.80 | 276 | 8 | 36 | A low, B high | e1 | testdb, withTxn |
| `web/src/pipeline/api.ts` | 331 | 16 | 4 | +1.26 | 104 | 7 | +2.46 | 1236 | 10 | 90 | A high, B high | e1 | r_note, s_note, p_note, a_note, hasNote, relTime |
| `web/src/ui/ReachNote.tsx` | 34 | 30 | 5 | +1.63 | 57 | 7 | +1.91 | 254 | 10 | 27 | A high, B high | e1 | useReach, ReachNote |
| `web/src/ui/CtxMenu.tsx` | 195 | 6 | 3 | +0.63 | 107 | 5 | +2.79 | 316 | 6 | 101 | B high | e1 | CtxSub, CtxMenu, CtxItem, viewport, CtxButton, subOffsets |
| `spheres/schedule/ui/api.ts` | 281 | 7 | 2 | +1.14 | 43 | 4 | +2.16 | 275 | 6 | 38 | A high, B high | e2 | footer, moveId, TermRow, fromDate, MoveBody, postMove |
| `connectors/facebook/api/graph-client.js` | 167 | 1 | 3 | -1.00 | 0 | 6 | -2.26 | 0 | 9 | 0 | B low | e2 | POST_FIELDS |
| `spheres/relationships/api/read.js` | 670 | 1 | 3 | -1.00 | 0 | 6 | -2.26 | 0 | 10 | 0 | B low | e3 | jsonStr, tripleKey, groupName, matchSide, personJson, buildPeople |
| `spheres/relationships/ui/api.ts` | 300 | 3 | 2 | +0.37 | 92 | 4 | +2.85 | 455 | 6 | 89 | B high | e2 | userId, eventId, claimId, lastname, linkedin, removedAt |
| `web/src/lib/url-state.ts` | 131 | 20 | 5 | +1.26 | 65 | 8 | +1.91 | 174 | 12 | 45 | A high, B high | e1 | readRaw, url-state, writeParam, useUrlParam, useStringParam |
| `spheres/social/ui/Rolodex.tsx` | 1026 | 3 | 1 | +1.00 | 32 | 3 | +2.15 | 389 | 4 | 29 | B high | e1 | NO_STAR, onSweep, listIcon, isSoured, gridIcon, setQuery |
| `web/src/app/AuthGate.tsx` | 234 | 6 | 1 | +1.63 | 21 | 4 | +1.51 | 75 | 6 | 15 | A high, B high | e1 | AuthCtx, AuthGate, onSignedIn, LoginScreen, AuthUpdateCtx, applyStoredPrefs |
| `connectors/sonas/api/upsert.js` | 317 | 1 | 3 | -1.00 | 0 | 5 | -2.10 | 0 | 7 | 0 | B low | e3 | captureEventChanges |
| `web/src/lib/auth.ts` | 480 | 11 | 6 | +0.55 | 114 | 7 | +2.54 | 630 | 9 | 106 | B high | e2 | AppRun, addedAt, addedBy, AppUser, authHint, grantsOf |
| `server/shared/credentials.js` | 278 | 24 | 4 | +1.63 | 38 | 8 | +1.42 | 145 | 12 | 14 | A high, B high | e1 | fieldOf, readToken, updatedBy, writeToken, setCredential, clearCredential |
| `spheres/social/ui/api.ts` | 589 | 15 | 4 | +1.20 | 59 | 8 | +1.82 | 490 | 12 | 48 | A high, B high | e3 | tiktok, sentAt, LastMsg, takenAt, PerfPost, GrowthRow |
| `web/src/app/sphere.ts` | 33 | 18 | 4 | +1.37 | 1 | 6 | -1.63 | 2 | 10 | 0 | A high, B low | e2 | NavItem |
| `web/src/ui/FilterBar.tsx` | 144 | 2 | 4 | -0.63 | 39 | 3 | +2.33 | 449 | 5 | 37 | B high | e1 | onAll, onNone, optionsOf, FilterBar, FilterCheck, FacetButton |
| `connectors/awsconnect/api/sync.test.js` | 302 | 0 | 0 | +0.00 | 50 | 2 | +2.93 | 102 | 2 | 50 | B high | e1 | upserts, dimHandlers |
| `spheres/social/ui/CampaignPipeline.tsx` | 151 | 2 | 1 | +0.63 | 24 | 2 | +2.26 | 228 | 3 | 22 | B high | e1 | onNew, onPeople, selectedId, CampaignList, deleteAction, CampaignPipeline |
| `server/shared/events.js` | 57 | 1 | 4 | -1.26 | 1 | 6 | -1.63 | 6 | 8 | 1 | A low, B low | e3 | createDoorbell |
| `connectors/linkedin/api/memdb.js` | 185 | 0 | 2 | -1.26 | 0 | 3 | -1.63 | 0 | 5 | 0 | A low, B low | e1 | rowKey |
| `server/shared/party.js` | 424 | 1 | 5 | -1.46 | 2 | 9 | -1.37 | 3 | 13 | 2 | A low, B low | e3 | claimKey, postClaim, liveClaims, jsonEmails, postRetire, listParties |
| `spheres/publicity/ui/api.ts` | 45 | 3 | 2 | +0.37 | 58 | 4 | +2.43 | 179 | 5 | 55 | B high | e1 | created_at, addCoverage, coverageCount, CoverageCount, CoverageInput, published_date |
| `web/src/ui/HoverTip.tsx` | 36 | 1 | 3 | -1.00 | 21 | 3 | +1.77 | 99 | 5 | 20 | B high | e1 | HoverTip |
| `web/src/ui/SectionHeader.tsx` | 37 | 19 | 8 | +0.79 | 78 | 9 | +1.97 | 207 | 12 | 59 | B high | e1 | SectionHeader |
| `web/src/lib/use-api-view.ts` | 165 | 38 | 11 | +1.13 | 95 | 16 | +1.62 | 315 | 24 | 57 | A high, B high | e1 | paramsOf, staleTime, useApiView, apiViewKey, apiViewPath, resolveRoute |
| `connectors/xero/api/sync.js` | 242 | 1 | 2 | -0.63 | 0 | 5 | -2.10 | 0 | 8 | 0 | B low | e3 | syncSettings, OFFSET_CHUNK, syncPaginated, syncOffsetWalk, newWatermarkMs, setOffsetCursor |
| `spheres/library/api/providers.js` | 50 | 1 | 2 | -0.63 | 0 | 5 | -2.10 | 0 | 7 | 0 | B low | e2 | appCreds |
| `spheres/schedule/api/providers/rezdy.js` | 215 | 1 | 1 | +0.00 | 78 | 4 | +2.70 | 290 | 5 | 77 | B high | e2 | rezdy, GRID_SQL, deriveSlots, OCCUPANCY_SQL |
| `web/src/pipeline/ContactPanel.tsx` | 319 | 3 | 1 | +1.00 | 19 | 3 | +1.68 | 45 | 4 | 16 | B high | e2 | eventDate, NoteEditor, afterWrite, memberStage, ContactPanel, stageGuidance |
| `web/src/ui/atoms.tsx` | 77 | 44 | 10 | +1.35 | 51 | 12 | +1.32 | 357 | 18 | 37 | A high, B high | e1 | PillTone, AvatarSize, CountBadge, StatusPill |
| `web/src/lib/stream.ts` | 108 | 2 | 3 | -0.37 | 59 | 5 | +2.25 | 434 | 6 | 57 | B high | e1 | stream, isAbort, readSse, postSse, onFrame, SseFrame |
| `web/src/ui/boardDrag.ts` | 182 | 4 | 2 | +0.63 | 26 | 3 | +1.97 | 311 | 6 | 22 | B high | e3 | onDrop, onLift, canDrag, specFor, fromKey, dropSpec |
| `web/src/ui/DeepLink.tsx` | 101 | 8 | 5 | +0.43 | 62 | 6 | +2.13 | 175 | 11 | 54 | B high | e1 | DeepLink |
| `connectors/otter/api/memdb.js` | 187 | 0 | 2 | -1.26 | 0 | 2 | -1.26 | 0 | 3 | 0 | A low, B low | e2 | COALESCE_COLS |
| `connectors/rezdy/api/sync.js` | 204 | 1 | 2 | -0.63 | 0 | 4 | -1.89 | 0 | 6 | 0 | B low | e3 | syncPerCategory |
| `connectors/sonas/api/sync.js` | 251 | 1 | 2 | -0.63 | 0 | 4 | -1.89 | 0 | 6 | 0 | B low | e3 | syncPub, syncTabular, syncTabularDetail |
| `spheres/reputation/api/read.js` | 174 | 1 | 2 | -0.63 | 0 | 4 | -1.89 | 0 | 6 | 0 | B low | e3 | cleanText, listPlaces, listReviews, undismissReview |
| `spheres/schedule/api/instance.js` | 43 | 0 | 1 | -0.63 | 0 | 4 | -1.89 | 0 | 5 | 0 | B low | e2 | reconcileDue |
| `server/shared/connector-tenant.js` | 45 | 21 | 6 | +1.14 | 41 | 9 | +1.38 | 144 | 14 | 20 | A high, B high | e3 | tenantOf, connector-tenant |
| `server/shared/sync-runs.js` | 199 | 26 | 8 | +1.07 | 65 | 14 | +1.40 | 259 | 24 | 39 | A high, B high | e1 | endRun, syncDue, BEAT_MS, syncBusy, beginRun, elapsedMs |
| `spheres/financial/ui/fy.ts` | 115 | 1 | 3 | -1.00 | 25 | 5 | +1.46 | 155 | 7 | 24 | B high | e1 | fy, FYRow, fyRows, fyYear, fyLabel, fyWindow |
| `connectors/awsconnect/api/sync.js` | 384 | 13 | 2 | +1.70 | 11 | 5 | +0.72 | 30 | 7 | 11 | A high | e1 | venueTz, listKey, listAll, syncCost, windowMs, syncUsers |
| `web/src/ui/ParamChips.tsx` | 69 | 9 | 5 | +0.54 | 52 | 7 | +1.83 | 201 | 10 | 43 | B high | e1 | allLabel, ParamChips, ChipOption |
| `web/src/ui/FreshnessNote.tsx` | 57 | 11 | 6 | +0.55 | 56 | 8 | +1.77 | 166 | 10 | 45 | B high | e1 | FreshnessNote |
| `scripts/import-meta-exports.mjs` | 804 | 0 | 0 | +0.00 | 37 | 3 | +2.29 | 161 | 5 | 37 | B high | e2 | winKey, mdyToIso, basename, fileLabel, permalink, postIdCell |
| `web/src/lib/clicklog.ts` | 34 | 6 | 3 | +0.63 | 31 | 5 | +1.66 | 70 | 6 | 25 | B high | e1 | clicklog, logDeepLink, openDeepLink |
| `server/shared/grants.js` | 224 | 3 | 12 | -1.26 | 6 | 18 | -1.00 | 141 | 28 | 5 | A low | e3 | needVerb, VERB_ORDER, DATA_TOKEN, formatToken, parseGrants, warnedTokens |
| `web/src/pipeline/Campaigns.tsx` | 144 | 3 | 1 | +1.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e3 | CampaignCard |
| `connectors/github/hook.js` | 53 | 0 | 1 | -0.63 | 0 | 3 | -1.63 | 0 | 5 | 0 | B low | e2 | subscriptionCount |
| `web/src/ui/GroupedList.tsx` | 51 | 3 | 4 | -0.26 | 31 | 4 | +1.86 | 117 | 7 | 28 | B high | e1 | renderBody, GroupedList |
| `server/shared/ready.js` | 329 | 1 | 6 | -1.63 | 20 | 12 | +0.46 | 124 | 18 | 19 | A low | e3 | staleIds, freshIds, workQueue, readyWork, makeReader, describeWork |
| `spheres/social/api/instance.js` | 45 | 0 | 1 | -0.63 | 20 | 4 | +1.46 | 66 | 7 | 20 | B high | e2 | loadVocab, stagePassDue |
| `server/shared/contract.js` | 154 | 1 | 5 | -1.46 | 4 | 8 | -0.63 | 43 | 11 | 3 | A low | e3 | isFunc, isString, jobProblems, validateOwnerConfig, reservedNameProblem, RESERVED_SHELL_NAMES |
| `web/src/pipeline/StagesEditor.tsx` | 198 | 2 | 1 | +0.63 | 10 | 2 | +1.46 | 29 | 3 | 8 | B high | e2 | StageRow, onRemove, StagesEditor |
| `connectors/googlechat/api/sync.js` | 304 | 1 | 2 | -0.63 | 1 | 5 | -1.46 | 5 | 8 | 1 | B low | e3 | nowIso, floorIso, syncSpace, dumpSpaces, persistPage, upsertSpaces |
| `server/shared/auth.js` | 1679 | 3 | 10 | -1.10 | 44 | 15 | +0.98 | 230 | 30 | 42 | A low | e1 | newCode, startMs, codeStr, newToken, sendMail, setPrefs |
| `web/src/lib/use-anchor.ts` | 26 | 2 | 4 | -0.63 | 29 | 6 | +1.43 | 35 | 8 | 27 | B high | e1 | useAnchor, use-anchor |
| `web/src/lib/view-registry.ts` | 108 | 8 | 6 | +0.26 | 50 | 7 | +1.79 | 129 | 9 | 42 | B high | e1 | nextId, ChoiceSet, view-registry, anchorElement, registerAnchor, registerChoice |
| `scripts/refresh-meta-recent.mjs` | 235 | 0 | 0 | +0.00 | 19 | 2 | +2.05 | 97 | 3 | 19 | B high | e2 | skillRef, runSkill, faultText, overseerUp, IG_HANDLES, resolveOwnPk |
| `web/src/lib/view-scope.ts` | 27 | 11 | 3 | +1.18 | 13 | 5 | +0.87 | 40 | 6 | 2 | A high | e1 | useSlot, ViewScope, view-scope |
| `spheres/reputation/ui/api.ts` | 71 | 5 | 2 | +0.83 | 15 | 4 | +1.20 | 129 | 5 | 12 | B high | e1 | avgRating, localGuide, totalScore, placeTitle, publishedAt, ownerResponse |
| `connectors/otter/api/jobs.js` | 274 | 2 | 3 | -0.37 | 1 | 6 | -1.63 | 18 | 9 | 1 | B low | e3 | ACCOUNT_ID, UPSERT_CHUNK, validateList, recordingRow, validateFetch, UPSERT_RECORDINGS_SQL |
| `web/src/ui/Chips.tsx` | 38 | 3 | 6 | -0.63 | 25 | 6 | +1.30 | 122 | 10 | 22 | B high | e1 | ChipRow |
| `web/src/lib/breakpoint.ts` | 18 | 3 | 5 | -0.46 | 30 | 6 | +1.46 | 64 | 10 | 27 | B high | e1 | breakpoint, useDesktop, DESKTOP_QUERY, DESKTOP_MIN_PX, subscribeDesktop |
| `spheres/library/ui/SearchBar.tsx` | 104 | 2 | 1 | +0.63 | 8 | 2 | +1.26 | 51 | 3 | 6 | B high | e1 | setText, SearchBar, SETTLE_MS, useAnyReach, useQueryParam, useSelectedSources |
| `spheres/schedule/api/providers/sonas.js` | 157 | 4 | 1 | +1.26 | 2 | 4 | -0.63 | 25 | 5 | 2 | A high | e3 | headcount, WEDDINGS_SQL, utcSqlString, VENUE_TZ_SQL, mapWeddingRow, WEDDING_STATUS |
| `web/src/ui/SearchInput.tsx` | 39 | 1 | 4 | -1.26 | 12 | 6 | +0.63 | 23 | 8 | 11 | A low | e1 | autoFocus, SearchInput |
| `spheres/publicity/ui/CoverageSection.tsx` | 96 | 2 | 1 | +0.63 | 8 | 2 | +1.26 | 23 | 3 | 6 | B high | e1 | onAdded, coverageBadge, coverageSection, CoverageSection |
| `connectors/deputy/api/upsert.js` | 134 | 1 | 2 | -0.63 | 1 | 4 | -1.26 | 13 | 6 | 1 | B low | e3 | dateOnly, epochToMysql |
| `spheres/social/api/read.js` | 1491 | 1 | 4 | -1.26 | 5 | 10 | -0.63 | 9 | 20 | 5 | A low | e3 | ownPk, isMember, draftRow, actorFor, unreadFor, unpackMsg |
| `spheres/library/api/read.js` | 99 | 1 | 2 | -0.63 | 1 | 4 | -1.26 | 9 | 6 | 1 | B low | e3 | itemRoute, defaultLog, searchRoute, buildHandleApi |
| `spheres/schedule/reconcile.js` | 80 | 0 | 1 | -0.63 | 1 | 4 | -1.26 | 9 | 5 | 1 | B low | e2 | CLOSE_SQL, STALE_SQL, reconcilePass |
| `server/app.js` | 1352 | 0 | 1 | -0.63 | 5 | 20 | -1.26 | 8 | 35 | 5 | B low | e2 | _mods, readGate, relToRepo, checkAuth, adminOnly, _hookSweep |
| `spheres/customer-service/api/read.js` | 125 | 1 | 2 | -0.63 | 1 | 4 | -1.26 | 6 | 6 | 1 | B low | e3 | DAYS_MAX, CAL_DATE, callsParams |
| `server/shared/http-json.js` | 50 | 1 | 4 | -1.26 | 3 | 6 | -0.63 | 8 | 8 | 2 | A low | e3 | http-json |
| `connectors/square/api/upsert.js` | 137 | 1 | 2 | -0.63 | 1 | 4 | -1.26 | 5 | 5 | 1 | B low | e3 | isoToLocal |
| `spheres/publicity/api/read.js` | 115 | 1 | 2 | -0.63 | 1 | 4 | -1.26 | 5 | 6 | 1 | B low | e3 | buildApi, coverageList, coverageCounts |
| `spheres/coord/prelink.js` | 74 | 0 | 1 | -0.63 | 1 | 4 | -1.26 | 3 | 5 | 1 | B low | e2 | prelinkMeetings |
| `agent/server.js` | 561 | 0 | 1 | -0.63 | 2 | 8 | -1.26 | 2 | 14 | 2 | B low | e2 | TLS_KEY, newTurn, TLS_CERT, BODY_CAP, logDetail, toolWiring |
| `connectors/clover/api/sync.js` | 214 | 1 | 2 | -0.63 | 1 | 4 | -1.26 | 1 | 5 | 1 | B low | e3 | syncOrders, watermarkMs, localZoneOf |
| `connectors/github/api/sync.js` | 131 | 1 | 1 | +0.00 | 0 | 4 | -1.89 | 0 | 6 | 0 | B low | e2 | loadShas, touchFile, upsertFile |
| `web/src/ui/FilterRow.tsx` | 23 | 3 | 3 | +0.00 | 15 | 2 | +1.83 | 35 | 3 | 12 | B high | e3 | FilterRow |
| `web/src/ui/PersonRow.tsx` | 66 | 3 | 5 | -0.46 | 35 | 8 | +1.34 | 137 | 10 | 32 | B high | e1 | PersonRow |
| `web/src/ui/useCardSelection.ts` | 142 | 3 | 3 | +0.00 | 21 | 3 | +1.77 | 51 | 5 | 18 | B high | e1 | groupFor, shiftKey, ClickLike, CardGestures, CardSelection, useCardSelection |
| `web/src/ui/Overlay.tsx` | 75 | 11 | 10 | +0.09 | 62 | 10 | +1.66 | 215 | 13 | 51 | B high | e1 | Overlay, panelClassName |
| `server/shared/access.test.js` | 421 | 0 | 0 | +0.00 | 20 | 3 | +1.73 | 62 | 4 | 20 | B high | e1 | agentP, machineP, PL_EMPTY, openDecl, listDecl, noSession |
| `connectors/awsconnect/api/upsert.js` | 238 | 0 | 2 | -1.26 | 3 | 5 | -0.46 | 47 | 7 | 3 | A low | e3 | fmtFor, DAY_NUM, localOf, fmtCache, tsToMysql, upsertUsers |
| `server/shared/job-runs.js` | 74 | 6 | 4 | +0.37 | 26 | 6 | +1.33 | 84 | 10 | 20 | B high | e3 | runBase, job-runs, runBPersist, normalizeResolvedVersion |
| `agent/transcribe.js` | 115 | 1 | 1 | +0.00 | 26 | 4 | +1.70 | 46 | 5 | 25 | B high | e2 | dialogueOf, transcribe, MAX_AUDIO_BYTES, transcribeChannel, transcribeEnabled, transcribeAuthorized |
| `web/src/ui/SelectableCard.tsx` | 72 | 3 | 3 | +0.00 | 32 | 5 | +1.69 | 139 | 6 | 29 | B high | e1 | openLabel, SelectableCard |
| `server/shared/hash.js` | 8 | 2 | 2 | +0.00 | 24 | 4 | +1.63 | 73 | 5 | 22 | B high | e1 | sha256 |
| `spheres/coord/ui/views/Board.tsx` | 141 | 1 | 1 | +0.00 | 0 | 3 | -1.63 | 0 | 4 | 0 | B low | e1 | columnOf |
| `spheres/financial/ui/views/Labour.tsx` | 276 | 1 | 1 | +0.00 | 0 | 3 | -1.63 | 0 | 4 | 0 | B low | e1 | pctLabel, deltaLabel, hoursLabel, moneyOrDash, hoursOrDash |
| `spheres/schedule/ui/views/Week.tsx` | 306 | 1 | 1 | +0.00 | 0 | 3 | -1.63 | 0 | 4 | 0 | B low | e1 | ISO_DAY, draftOf, parseWeek, rangeLabel, serializeWeek, PendingConfirm |
| `spheres/social/ui/PeopleSection.tsx` | 251 | 1 | 1 | +0.00 | 0 | 3 | -1.63 | 0 | 4 | 0 | B low | e1 | parseOff, pkFromPath, parseQuery, parseCollab, desktopLike, STARS_CODEC |
| `connectors/tiktok/insights-sync.js` | 84 | 0 | 0 | +0.00 | 0 | 3 | -1.63 | 0 | 4 | 0 | B low | e2 | TOKEN_FILE |
| `spheres/financial/api/read.test.js` | 652 | 0 | 0 | +0.00 | 0 | 3 | -1.63 | 0 | 4 | 0 | B low | e2 | SRC_FRAG, getVocab, fullPlan, ACCT_FRAG, labourPlan, VOCAB_ROWS |
| `spheres/social/api/read.test.js` | 1443 | 0 | 0 | +0.00 | 0 | 3 | -1.63 | 0 | 4 | 0 | B low | e2 | seedUnreadThread |
| `web/src/app/ChatPane.tsx` | 86 | 1 | 1 | +0.00 | 11 | 2 | +1.55 | 28 | 3 | 10 | B high | e1 | ChatPane, ChatUnreachable |
| `server/shared/spar-pipeline.js` | 623 | 5 | 4 | +0.20 | 39 | 9 | +1.33 | 105 | 13 | 34 | B high | e1 | claimSql, LAST_TOUCH, loadClaims, configPath, MEMBER_SQL, memberJson |
| `server/shared/error-codes.test.js` | 82 | 0 | 0 | +0.00 | 10 | 2 | +1.46 | 13 | 3 | 10 | B high | e1 | error-codes.test |
| `spheres/coord/ui/api.ts` | 204 | 5 | 4 | +0.20 | 21 | 6 | +1.14 | 114 | 8 | 18 | B high | e1 | sweepNow, TaskState, LeaderRow, sourceKind, methodDate, createTime |
| `web/src/lib/navigate.ts` | 57 | 8 | 10 | -0.20 | 32 | 10 | +1.06 | 103 | 14 | 24 | B high | e1 | navigate, closeSecondary |
| `web/src/app/PrefsPanel.tsx` | 181 | 1 | 1 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e1 | DATE_SAMPLE |
| `web/src/lib/view-slot.test.tsx` | 233 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e2 | view-slot.test |
| `spheres/financial/ui/views/Products.tsx` | 199 | 1 | 1 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e1 | MoveChip, CHANNEL_NAME |
| `spheres/projects/ui/views/Portfolio.tsx` | 169 | 1 | 1 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e1 | ProjectCard, PortfolioBoard |
| `spheres/relationships/ui/views/People.tsx` | 233 | 1 | 1 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e1 | handleOf, subtitleOf, stagePills, presenceMarks, SOURCE_OPTIONS |
| `spheres/schedule/ui/views/Almanac.tsx` | 432 | 1 | 1 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e1 | dayOf, termTag, windowOf, termSpan, CAT_WORD, parseYear |
| `spheres/social/ui/CampaignsSection.tsx` | 163 | 1 | 1 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e1 | CampRoute, routeFromPath |
| `connectors/awsconnect/api/client.test.js` | 86 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | fakeSign, clientWith |
| `connectors/awsconnect/api/upsert.test.js` | 170 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | contactFixture |
| `connectors/deputy/api/upsert.test.js` | 187 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | unitFixture, rosterFixture, employeeFixture, timesheetFixture |
| `connectors/dropbox/api/dropbox-client.test.js` | 395 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | tokenOk, makeConn, dropbox-client.test |
| `connectors/github/api/sync.test.js` | 168 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | BAD_YAML, GOOD_YAML |
| `connectors/googlereviews/api/client.test.js` | 116 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | fakeHttps |
| `connectors/googlereviews/api/sync.test.js` | 273 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | provIds, serpReview |
| `connectors/googlereviews/api/upsert.test.js` | 216 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | findSQL, placeFixture, reviewFixture, PLACE_SCHEMA_COLS, REVIEW_SCHEMA_COLS |
| `connectors/linkedin/api/bl00.test.js` | 68 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | LIVE_URN, bl00.test |
| `connectors/linkedin/api/bl01.test.js` | 70 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | bl01.test |
| `connectors/linkedin/api/bl02.test.js` | 88 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | bl02.test, inboxEnvelope |
| `connectors/linkedin/api/bl03.test.js` | 91 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | bl03.test |
| `connectors/linkedin/api/bl04.test.js` | 81 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | seedEdges, bl04.test, profFixture, connFixture |
| `connectors/linkedin/api/bl05.test.js` | 84 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | bl05.test |
| `connectors/onedrive/api/graph-client.test.js` | 434 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | UNFACETED_AUDIO, graph-client.test |
| `connectors/rezdy/api/upsert.test.js` | 344 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | bookingFixture |
| `connectors/sonas/api/client.test.js` | 264 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | makeFakeWs, sonasServer |
| `connectors/sonas/api/upsert.test.js` | 325 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | eventFixture, financialRecordFixture |
| `connectors/spar/api/upsert.test.js` | 212 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | callFor, insertCols, approachRow, campaignRow |
| `connectors/tiktok/api/credentials.test.js` | 141 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | TIKTOK_ENV |
| `connectors/xero/api/sync.test.js` | 327 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | mkJournal, journalRange |
| `connectors/xero/api/upsert.test.js` | 242 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | invoiceFixture, accountFixture, journalFixture, bankTransferFixture, bankTransactionFixture |
| `spheres/coord/api/decode.test.js` | 140 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | chatMsg, taskMsg, decode.test, selfTaskMsg, completedMsg |
| `spheres/coord/api/instance.test.js` | 75 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | prelinkHook, instance.test |
| `spheres/coord/api/jobs-a.test.js` | 307 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | recRow, REC_TENANT, fullVerdict, jobs-a.test, derivedConn |
| `spheres/customer-service/api/read.test.js` | 99 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | okPlan |
| `spheres/customer-service/api/transcripts.test.js` | 118 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | transcripts.test |
| `spheres/financial/api/deals.test.js` | 212 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e2 | plainApi, deals.test |
| `spheres/library/api/read.test.js` | 164 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | fakeRegistry |
| `spheres/partnership/api/read.test.js` | 302 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | emptyApi |
| `spheres/projects/api/derive.test.js` | 162 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e2 | derive.test |
| `spheres/projects/api/read.test.js` | 338 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e3 | WRITE_ROUTES |
| `spheres/publicity/api/cursor.test.js` | 155 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | seedMember, cursor.test |
| `spheres/publicity/api/look-claim.test.js` | 116 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | HOOK_CLAIMS, look-claim.test |
| `spheres/relationships/api/read.test.js` | 663 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e3 | withClaims |
| `spheres/reputation/api/dismiss-plural.test.js` | 51 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | missingColumn, dismiss-plural.test |
| `spheres/reputation/api/read.test.js` | 168 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | REVIEW_ROW |
| `spheres/schedule/api/almanac.test.js` | 450 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | almanac.test |
| `spheres/schedule/api/config.test.js` | 104 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | goodRaw, config.test |
| `spheres/schedule/api/read.test.js` | 464 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e3 | PENDING_NOW, pendingWindow, providerHandlers, withinPendingWeek |
| `spheres/schedule/api/reconcile-logic.test.js` | 231 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | reconcile-logic.test |
| `spheres/schedule/api/reconcile.test.js` | 203 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | dueConn, passConn, reconcile.test, CURRENT_BY_ORDER, CHANGES_BY_ORDER |
| `spheres/social/api/ai01.test.js` | 87 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | ai01.test |
| `spheres/social/api/ai02.test.js` | 157 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | NON_INFL, ai02.test, SMALL_INFL |
| `spheres/social/api/ai03.test.js` | 98 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | ai03.test |
| `spheres/social/api/bi02.test.js` | 103 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | bi02.test, threadPage |
| `spheres/social/api/contacts-filter.test.js` | 233 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | seededPks, seedMatrix, nextThread, contacts-filter.test |
| `spheres/social/api/drafts.test.js` | 227 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | drafts.test, makeCampaign, seedMarketingContact |
| `spheres/social/api/flip-subset.test.js` | 129 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | gateRow, CAMP_ROW, IS_MEMBER, KNOWN_STAGE, flip-subset.test |
| `spheres/social/api/freshness.test.js` | 53 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | A_STALE, A_FRESH, seedMarketingVisited |
| `spheres/social/api/performance.test.js` | 362 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | MEDIA_B, MEDIA_A, FB_POST_ID, LONG_CAPTION, seedPerformance, performance.test |
| `spheres/social/api/stage-cursor.test.js` | 142 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | stage-cursor.test |
| `server/shared/anthropic.test.js` | 81 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | anthropic.test |
| `server/shared/chat.test.js` | 214 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e3 | DB_STUB, chat.test |
| `server/shared/click-log.test.js` | 33 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | recordingConn, click-log.test |
| `server/shared/contract.test.js` | 200 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e3 | fakeSphere, fakeConnector |
| `server/shared/credential-manifests.test.js` | 80 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | fixtureRoot, writeManifest, credential-manifests.test |
| `server/shared/deepseek.test.js` | 63 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | deepseek.test |
| `server/shared/events.test.js` | 68 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | eventsIn, fakeClient, events.test |
| `server/shared/job-claims.test.js` | 197 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | fakeTable, job-claims.test |
| `server/shared/ollama.test.js` | 50 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | ollama.test |
| `server/shared/ready.test.js` | 114 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 3 | 0 | B low | e3 | ready.test, betaConfig, alphaConfig |
| `server/shared/runbook.test.js` | 46 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | dirWith, runbook.test |
| `server/shared/spar-pipeline.walls.test.js` | 236 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e3 | ctxOf, spar-pipeline.walls.test |
| `server/shared/stage-advance.test.js` | 146 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e3 | viewRow |
| `server/shared/tenancy.test.js` | 139 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | tenancy.test |
| `server/shared/trail.test.js` | 81 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | trail.test |
| `server/shared/venue-date.test.js` | 67 | 0 | 0 | +0.00 | 0 | 2 | -1.26 | 0 | 2 | 0 | B low | e2 | venue-date.test |
| `agent/system-prompt.js` | 37 | 1 | 1 | +0.00 | 11 | 3 | +1.18 | 26 | 5 | 10 | B high | e2 | systemPrompt, system-prompt |
| `spheres/library/api/hits.js` | 86 | 2 | 2 | +0.00 | 18 | 5 | +1.17 | 98 | 8 | 17 | B high | e1 | Q_MAX, HIT_KINDS, isNotFound, PAGE_LIMIT, EMPTY_SEARCH, searchParams |
| `connectors/instagram/api/shortcode.js` | 45 | 3 | 3 | +0.00 | 14 | 4 | +1.14 | 131 | 7 | 11 | B high | e3 | shortcode, IG_ALPHABET, shortcodeToPk, pkToShortcode, shortcodeFromPermalink |
| `agent/agreement.test.js` | 263 | 0 | 0 | +0.00 | 7 | 2 | +1.14 | 11 | 3 | 7 | B high | e1 | pathParams, derivedNames, agreement.test |
| `spheres/financial/ui/export.ts` | 208 | 1 | 1 | +0.00 | 10 | 3 | +1.10 | 134 | 4 | 9 | B high | e1 | setOff, NUM_FMT, viewWord, localName, sheetName, viewLabel |
| `server/shared/click-log.js` | 11 | 1 | 3 | -1.00 | 18 | 6 | +1.00 | 35 | 8 | 17 |  | e1 | click-log, recordClick |
| `connectors/spar/api/parse.js` | 315 | 1 | 3 | -1.00 | 2 | 6 | -1.00 | 45 | 9 | 1 |  | e3 | dateN, tsvText, asGiven, fileStem, needsFix, indentOf |
| `connectors/xero/api/upsert.js` | 333 | 1 | 3 | -1.00 | 2 | 6 | -1.00 | 28 | 9 | 1 |  | e3 | mysqlDt, LINE_SQL, LINE_COLS, xeroDateMs, TRACKING_SQL, paymentTarget |
| `spheres/schedule/api/read.js` | 335 | 1 | 3 | -1.00 | 2 | 6 | -1.00 | 8 | 8 | 2 |  | e3 | metaRoute, slotsRoute, ghostEntry, rangeRoute, upsertEntry, mergePending |
| `spheres/financial/api/read.js` | 904 | 1 | 3 | -1.00 | 3 | 8 | -0.89 | 18 | 15 | 3 |  | e3 | putCell, rentRow, SEG_CAT, rezdyRows, sonasRows, sectionOf |
| `spheres/social/api/jobs.js` | 725 | 1 | 3 | -1.00 | 3 | 8 | -0.89 | 4 | 12 | 2 |  | e3 | GATE_BATCH, buildCrmJobs, anyMarketing, CLEAN_HEALTH, threadMembers, truncateLines |
| `connectors/spar/api/upsert.js` | 215 | 1 | 3 | -1.00 | 2 | 5 | -0.83 | 65 | 7 | 1 |  | e3 | pkCount, clipRow, segRows, valueRows, passStart, upsertRows |
| `web/src/pipeline/Roster.tsx` | 159 | 3 | 1 | +1.00 | 5 | 2 | +0.83 | 5 | 3 | 4 |  | e2 | isDue, rowBadges |
| `web/src/lib/download.ts` | 17 | 1 | 3 | -1.00 | 2 | 5 | -0.83 | 6 | 6 | 1 |  | e2 | saveBlob |
| `spheres/customer-service/ui/api.ts` | 164 | 1 | 2 | -0.63 | 12 | 4 | +1.00 | 214 | 6 | 11 |  | e2 | agentId, CallDay, CallRow, CallRep, rangOut, waitSecs |
| `server/shared/chat.js` | 85 | 1 | 3 | -1.00 | 3 | 6 | -0.63 | 17 | 8 | 2 |  | e3 | toolRoutes, handleChat |
| `web/src/pipeline/CampaignBoard.tsx` | 260 | 1 | 2 | -0.63 | 1 | 3 | -1.00 | 11 | 4 | 1 |  | e3 | boardColumns, strayColumns, offFunnelColumns |
| `spheres/customer-service/api/policy.js` | 36 | 1 | 2 | -0.63 | 1 | 3 | -1.00 | 4 | 4 | 1 |  | e1 | loadPolicy |
| `web/src/lib/gesture-state.ts` | 42 | 1 | 3 | -1.00 | 2 | 4 | -0.63 | 6 | 6 | 1 |  | e2 | gesture-state, useGestureState |
| `server/shared/model-retry.js` | 44 | 2 | 4 | -0.63 | 2 | 6 | -1.00 | 8 | 8 | 0 |  | e3 | model-retry, sendWithRetry, FIVEXX_BACKOFF_MS |
| `web/src/app/chat-icon.tsx` | 9 | 1 | 2 | -0.63 | 1 | 3 | -1.00 | 4 | 4 | 0 |  | e2 | chatIcon, chat-icon |
| `spheres/social/api/statements.js` | 36 | 2 | 1 | +0.63 | 1 | 3 | -1.00 | 2 | 5 | 0 |  | e1 | insertSubset |
| `web/src/lib/slot-store.ts` | 100 | 7 | 3 | +0.77 | 12 | 5 | +0.80 | 120 | 6 | 5 |  | e1 | wakeView, SlotView, clearSlot, wakeParam, slot-store, getSnapshot |
| `spheres/financial/ui/period.ts` | 146 | 5 | 2 | +0.83 | 9 | 4 | +0.74 | 66 | 5 | 4 |  | e1 | fyStart, extendTo, monthsOf, shortMonth, orderRange, monthLabel |
| `spheres/financial/ui/api.ts` | 105 | 9 | 3 | +1.00 | 11 | 6 | +0.55 | 52 | 8 | 5 |  | e2 | PLRow, exGst, PLSource, prevExGst, LabourRow, ProductRow |
| `web/src/lib/format.ts` | 121 | 28 | 14 | +0.63 | 38 | 14 | +0.91 | 324 | 22 | 16 |  | e1 | prefs, fmtParts, weekStart, DateOrder, dateOrder, fmtRegion |
| `spheres/relationships/api/identity.js` | 286 | 1 | 2 | -0.63 | 2 | 5 | -0.83 | 66 | 7 | 1 |  | e2 | personId, igHandle, sparKeys, normName, sonasKeys, normEmail |
| `spheres/library/ui/api.ts` | 82 | 5 | 2 | +0.83 | 8 | 4 | +0.63 | 43 | 5 | 5 |  | e2 | HitKind, sourceOf, SourceId, SearchKind, ItemResponse, ProviderError |
| `web/src/lib/locale.ts` | 186 | 3 | 9 | -1.00 | 6 | 10 | -0.46 | 32 | 15 | 3 |  | e1 | regionIn, formatLocale, ES_419_REGIONS, activateLocale, ZH_HANT_REGIONS, ZH_HANS_REGIONS |
| `web/src/lib/useDoorbell.ts` | 29 | 1 | 3 | -1.00 | 3 | 5 | -0.46 | 5 | 6 | 2 |  | e1 | useDoorbell |
| `spheres/financial/api/policy.js` | 34 | 1 | 2 | -0.63 | 2 | 5 | -0.83 | 4 | 7 | 1 |  | e2 | dealsClaims, frozenClaims, claimedDealsCampaigns |
| `web/src/lib/journey.ts` | 181 | 11 | 7 | +0.41 | 18 | 6 | +1.00 | 111 | 8 | 13 |  | e2 | loadSeq, saveTail, sphereOf, loadTail, JourneyVerb, JOURNEY_CAP |
| `spheres/library/ui/Results.tsx` | 260 | 3 | 1 | +1.00 | 3 | 2 | +0.37 | 12 | 3 | 0 |  | e1 | fmtSize, KindGlyph, kindLabel, MediaGrid, reachLabel, SourceGroup |
| `web/src/lib/api.ts` | 121 | 34 | 15 | +0.74 | 34 | 18 | +0.58 | 151 | 30 | 11 |  | e1 | apiGet, apiPost, ApiError, refusalOf |
| `connectors/xero/api/xero-client.js` | 211 | 2 | 3 | -0.37 | 17 | 6 | +0.95 | 56 | 9 | 15 |  | e1 | xero-client, extractList, accessToken, PRODUCT_BASES, makeXeroClient, CONNECTIONS_URL |
| `connectors/linkedin/api/jobs.js` | 579 | 1 | 3 | -1.00 | 5 | 7 | -0.31 | 52 | 10 | 5 |  | e3 | isSelf, ownerUrn, profileUrn, connectedAt, connectedUrn, validateInbox |
| `connectors/rezdy/api/upsert.js` | 356 | 1 | 3 | -1.00 | 7 | 5 | +0.31 | 35 | 8 | 6 |  | e2 | categoryId, voucherCode, localToMysql, storedLocalText, captureBookingChanges, upsertCategoryProducts |
| `web/src/app/App.tsx` | 421 | 1 | 0 | +0.63 | 8 | 4 | +0.63 | 38 | 6 | 8 |  | e1 | resetKey, accessIcon, NoSuchPage, queryClient, settingsIcon, PaneBoundary |
| `spheres/social/ui/cards.tsx` | 152 | 4 | 3 | +0.26 | 12 | 4 | +1.00 | 55 | 5 | 8 |  | e1 | onFunnel, inCampaign, campaignNames, openMenuItems |
| `web/src/lib/tool-labels.ts` | 132 | 1 | 2 | -0.63 | 8 | 4 | +0.63 | 38 | 5 | 7 |  | e1 | tool-labels, activityLine, LABELLED_TOOLS |
| `server/shared/connector-health.js` | 119 | 1 | 3 | -1.00 | 8 | 6 | +0.26 | 33 | 8 | 7 |  | e1 | RUN_STRIP, healthRows, recentRuns, HEALTH_KINDS, HEALTH_REASONS, connector-health |
| `spheres/schedule/api/config.js` | 85 | 3 | 1 | +1.00 | 4 | 3 | +0.26 | 25 | 5 | 4 |  | e1 | isPosInt, validateConfig |
| `spheres/financial/ui/window.ts` | 46 | 1 | 2 | -0.63 | 2 | 4 | -0.63 | 20 | 5 | 1 |  | e2 | filterRows, OptionalSource, OPTIONAL_SOURCES |
| `connectors/deputy/api/sync.js` | 240 | 1 | 2 | -0.63 | 2 | 4 | -0.63 | 10 | 6 | 2 |  | e3 | maxId, maxMs, floorSec, sinceText, syncIncremental |
| `spheres/coord/api/jobs.js` | 228 | 1 | 2 | -0.63 | 2 | 4 | -0.63 | 20 | 5 | 1 |  | e3 | threadKey, replayLifecycle, reconstructTasks, LIFECYCLE_STATUS |
| `server/shared/versions.js` | 31 | 1 | 2 | -0.63 | 2 | 4 | -0.63 | 15 | 5 | 1 |  | e3 | latestRow, commitSha, decideAppend |
| `web/src/lib/drive.ts` | 285 | 1 | 2 | -0.63 | 2 | 4 | -0.63 | 14 | 6 | 1 |  | e3 | slotOf, DriveView, driveSplit, DriveEvent, driveFilter, surfaceView |
| `connectors/clover/api/upsert.js` | 214 | 1 | 2 | -0.63 | 2 | 4 | -0.63 | 7 | 5 | 2 |  | e3 | lineMods, sumCents, lineTaxes, msToLocal, lineDiscounts |
| `spheres/customer-service/api/calls.js` | 457 | 1 | 2 | -0.63 | 2 | 4 | -0.63 | 12 | 6 | 1 |  | e3 | daysOf, heatOf, costOf, repsOf, repName, todayIn |
| `web/src/app/match.ts` | 38 | 6 | 3 | +0.63 | 6 | 3 | +0.63 | 29 | 5 | 1 |  | e3 | activeNav, atAppRoot, activeSphere |
| `connectors/square/api/square-client.js` | 108 | 1 | 2 | -0.63 | 2 | 4 | -0.63 | 6 | 5 | 1 |  | e3 | square-client, SQUARE_VERSION, makeSquareClient |
| `web/src/app/AccessGrants.tsx` | 226 | 2 | 4 | -0.63 | 2 | 4 | -0.63 | 18 | 6 | 0 |  | e3 | refOf, ownToken, GrantCell, roleCover, VerbState, cellVerbs |
| `web/src/vite-env.d.ts` | 10 | 1 | 0 | +0.63 | 0 | 1 | -0.63 | 0 | 1 | 0 |  | e1 | vite-env.d |
| `server/shared/model-api.js` | 14 | 1 | 3 | -1.00 | 4 | 5 | -0.20 | 12 | 6 | 3 |  | e3 | model-api, runRunbookApi |
| `web/src/lib/interaction-context.ts` | 262 | 2 | 4 | -0.63 | 11 | 6 | +0.55 | 53 | 9 | 9 |  | e1 | byteSize, buildView, EMPTY_EXTRAS, JOURNEY_TAIL, ContextExtras, choiceFilters |
| `spheres/coord/api/jobs-a.js` | 399 | 1 | 2 | -0.63 | 9 | 5 | +0.54 | 20 | 7 | 8 |  | e2 | jobs-a, entityRows, buildMeetingJobs |
| `spheres/projects/api/read.js` | 652 | 1 | 3 | -1.00 | 5 | 6 | -0.17 | 15 | 10 | 5 |  | e3 | slugOk, badSlug, livesAt, postLink, parseRefs, projectId |
| `server/shared/datasets.js` | 72 | 3 | 8 | -0.89 | 9 | 12 | -0.26 | 38 | 25 | 6 |  | e1 | knownDataset, servedDatasets |
| `server/shared/anthropic.js` | 63 | 2 | 3 | -0.37 | 14 | 6 | +0.77 | 58 | 8 | 12 |  | e1 | anthropic, MODEL_IDS, runRunbook |
| `spheres/financial/ui/PeriodPicker.tsx` | 192 | 3 | 2 | +0.37 | 9 | 4 | +0.74 | 23 | 6 | 6 |  | e1 | atDefault, PeriodPicker |
| `spheres/coord/api/meetings.js` | 241 | 1 | 2 | -0.63 | 3 | 5 | -0.46 | 51 | 7 | 2 |  | e2 | getMeeting, clampLimit, likeFragment, getTranscript, searchMeetings, addressMeeting |
| `server/shared/closure.js` | 87 | 1 | 2 | -0.63 | 3 | 5 | -0.46 | 39 | 7 | 2 |  | e3 | rowFor, libRefs, notFound, storeDir, findTypeB, artifactRef |
| `spheres/social/api/performance.js` | 642 | 1 | 2 | -0.63 | 3 | 5 | -0.46 | 27 | 8 | 2 |  | e3 | fbType, igType, ownPks, fbPosts, igPosts, monthOf |
| `connectors/tiktok/api/insights-sync.js` | 181 | 1 | 2 | -0.63 | 3 | 5 | -0.46 | 17 | 7 | 2 |  | e3 | openId, videoRow, unixToVenue, unixSeconds, upsertVideo, loadTokenFile |
| `web/src/lib/chat-starters.ts` | 65 | 1 | 2 | -0.63 | 5 | 3 | +0.46 | 10 | 4 | 4 |  | e1 | BY_SPHERE, chat-starters, STARTER_SPHERES |
| `server/shared/db.js` | 92 | 44 | 25 | +0.51 | 38 | 20 | +0.58 | 104 | 30 | 15 |  | e1 | loadEnv, withWrite, savepointSeq |
| `server/shared/job-claims.js` | 108 | 2 | 3 | -0.37 | 13 | 6 | +0.70 | 47 | 8 | 11 |  | e1 | ttlMinutes, job-claims, intervalMinutes, sweepExpiredClaims |
| `web/src/ui/Board.tsx` | 445 | 7 | 8 | -0.12 | 28 | 10 | +0.94 | 138 | 15 | 21 |  | e1 | DropZone, DragCard, snapIndex, DragBoard, DropColumn, scrollLeft |
| `connectors/instagram/api/insights-sync.js` | 512 | 1 | 2 | -0.63 | 9 | 6 | +0.37 | 70 | 9 | 8 |  | e2 | dayUtc, ownerPk, mediaPk, pollSet, fullWalk, dayBounds |
| `agent/tools.js` | 202 | 1 | 2 | -0.63 | 9 | 6 | +0.37 | 61 | 10 | 8 |  | e2 | BI_BASE, rowFault, toolNames, toolEntries, deriveTools, fetchEntries |
| `spheres/projects/ui/views/Gantt.tsx` | 1113 | 1 | 1 | +0.00 | 9 | 3 | +1.00 | 32 | 4 | 8 |  | e1 | Gantt, MsPanel, onWrite, chainOf, SEC_HEAD, todayUTC |
| `spheres/social/api/bi01.test.js` | 372 | 0 | 0 | +0.00 | 6 | 2 | +1.00 | 25 | 2 | 6 |  | e1 | OWN_LONG, inboxPage, aRealPair, OWN_SHORT, bi01.test, igThreadId |
| `spheres/schedule/ui/ConfirmMove.tsx` | 74 | 1 | 1 | +0.00 | 6 | 2 | +1.00 | 27 | 3 | 5 |  | e1 | onConfirm, ConfirmMove |
| `connectors/rezdy/api/rezdy-client.js` | 156 | 1 | 2 | -0.63 | 6 | 4 | +0.37 | 26 | 6 | 5 |  | e2 | payloadOf, rezdy-client, makeRezdyClient |
| `spheres/social/ui/PerformanceSection.tsx` | 1026 | 1 | 1 | +0.00 | 1 | 3 | -1.00 | 15 | 4 | 1 |  | e1 | SortTh, onSort, labelOf, DeltaChip, FIRST_SLICE, genderLabel |
| `web/src/app/ChatAssistant.tsx` | 433 | 0 | 1 | -0.63 | 2 | 3 | -0.37 | 9 | 4 | 2 |  | e3 | DOCK_KEY, UserText, dockIcon, ToolLine, floatIcon, PanelMode |
| `spheres/financial/ui/views/ProfitAndLoss.tsx` | 452 | 1 | 1 | +0.00 | 1 | 3 | -1.00 | 9 | 4 | 1 |  | e1 | NetRow, segCount, parseSrc, monthNets, dashBelow, serializeSrc |
| `spheres/social/ui/CampaignBoard.tsx` | 605 | 1 | 1 | +0.00 | 1 | 3 | -1.00 | 8 | 4 | 1 |  | e3 | onReview, DraftChip, MemberCard |
| `server/shared/party.test.js` | 454 | 0 | 0 | +0.00 | 6 | 2 | +1.00 | 6 | 3 | 6 |  | e1 | CLAIM_ROW, party.test |
| `server/shared/tenant-conformance.test.js` | 250 | 0 | 0 | +0.00 | 6 | 2 | +1.00 | 6 | 3 | 6 |  | e1 | GROUP_TABLES, OWNER_COLUMNS, NO_TENANT_SCHEMA, PLATFORM_PIPELINE, tenant-conformance.test |
| `web/src/ui/highlight.ts` | 59 | 1 | 2 | -0.63 | 2 | 3 | -0.37 | 7 | 4 | 1 |  | e1 | highlightAnchor |
| `spheres/customer-service/ui/views/Calls.tsx` | 761 | 1 | 1 | +0.00 | 1 | 3 | -1.00 | 2 | 4 | 1 |  | e1 | hadOne, foldDays, sliceFor, LOG_SLICE, foldRepDays, TenantBlock |
| `server/shared/dispatch.test.js` | 430 | 0 | 0 | +0.00 | 1 | 3 | -1.00 | 1 | 4 | 1 |  | e2 | trailConn, personWith, dispatch.test |
| `web/src/app/AccessTenants.tsx` | 242 | 1 | 1 | +0.00 | 1 | 3 | -1.00 | 3 | 4 | 0 |  | e1 | OrgRow, OrgDrawer, AccessTenants |
| `spheres/projects/api/statements.js` | 115 | 1 | 1 | +0.00 | 1 | 3 | -1.00 | 11 | 5 | 0 |  | e2 | clearBall, updateBall, upsertLink, deleteLink, insertEvent, upsertProject |
| `spheres/projects/ui/api.ts` | 272 | 2 | 2 | +0.00 | 11 | 4 | +0.92 | 146 | 6 | 9 |  | e1 | notedBy, notedAt, locator, setBall, stageAt, LivesAt |
| `server/shared/secret-box.js` | 43 | 2 | 3 | -0.37 | 9 | 5 | +0.54 | 16 | 6 | 7 |  | e1 | IV_LEN, TAG_LEN, plaintext, secret-box |
| `spheres/financial/ui/labour-matrix.ts` | 137 | 1 | 2 | -0.63 | 3 | 4 | -0.26 | 75 | 5 | 2 |  | e2 | round1, unitIds, wagePct, perUnit, unitNames, LabourDay |
| `agent/drive-tools.js` | 163 | 1 | 2 | -0.63 | 8 | 6 | +0.26 | 26 | 9 | 7 |  | e2 | driveSeq, driveTool, driveTools, DRIVE_CODES, drive-tools, resolveDrive |
| `connectors/googlereviews/api/sync.js` | 232 | 1 | 2 | -0.63 | 3 | 4 | -0.26 | 6 | 6 | 3 |  | e3 | isoDate, markRun, reviewId, syncPlace, loadPlaces, searchesLast30d |
| `spheres/coord/api/instance.js` | 58 | 0 | 1 | -0.63 | 3 | 4 | -0.26 | 3 | 5 | 3 |  | e2 | prelinkDue, reconstructDue |
| `spheres/schedule/ui/week.ts` | 91 | 3 | 2 | +0.37 | 7 | 4 | +0.51 | 66 | 5 | 5 |  | e1 | DayCell, isToday, todayIso, mondayOf, weekRange, weekCells |
| `web/src/lib/error-codes.ts` | 213 | 9 | 6 | +0.37 | 14 | 8 | +0.51 | 66 | 12 | 5 |  | e1 | ErrorCode, errorText, localizeParams |
| `spheres/schedule/api/moves.js` | 112 | 1 | 2 | -0.63 | 4 | 5 | -0.20 | 30 | 6 | 3 |  | e2 | OPEN_SQL, CANCEL_SQL, cancelMove, INSERT_SQL, requestMove, RESOLVE_SQL |
| `web/src/lib/assistant-runtime.ts` | 268 | 1 | 2 | -0.63 | 5 | 4 | +0.20 | 19 | 5 | 4 |  | e3 | onChatId, ackedSeq, frameQueue, lastUserText, restoreChatId, ChatAdapterHandle |
| `connectors/deputy/api/deputy-client.js` | 135 | 1 | 2 | -0.63 | 5 | 4 | +0.20 | 15 | 6 | 4 |  | e2 | deputy-client, makeDeputyClient |
| `connectors/awsconnect/api/aws-client.js` | 132 | 1 | 2 | -0.63 | 4 | 5 | -0.20 | 9 | 8 | 3 |  | e1 | aws-client, makeAwsClient |
| `connectors/googlechat/api/chat-client.js` | 119 | 1 | 2 | -0.63 | 5 | 4 | +0.20 | 7 | 6 | 4 |  | e2 | chat-client, makeChatClient |
| `web/src/lib/overseer.ts` | 32 | 2 | 3 | -0.37 | 3 | 5 | -0.46 | 5 | 6 | 1 |  | e3 | probeOverseer, overseerSecret |
| `server/shared/ollama.js` | 51 | 2 | 2 | +0.00 | 10 | 4 | +0.83 | 27 | 5 | 8 |  | e1 | ollama, runRunbookLocal |
| `spheres/schedule/ui/views/Pending.tsx` | 164 | 1 | 1 | +0.00 | 5 | 2 | +0.83 | 14 | 3 | 5 |  | e1 | MoveRow, canWrite |
| `server/shared/tenant-registry.test.js` | 132 | 0 | 0 | +0.00 | 5 | 2 | +0.83 | 5 | 2 | 5 |  | e1 | withRegistry, FOUNDING_TENANTS, tenant-registry.test |
| `scripts/stage-flip-harness.mjs` | 142 | 0 | 0 | +0.00 | 5 | 2 | +0.83 | 5 | 3 | 5 |  | e1 | stage-flip-harness |
| `spheres/financial/ui/matrix.ts` | 109 | 2 | 3 | -0.37 | 8 | 5 | +0.43 | 66 | 7 | 6 |  | e1 | perfNet, DisplayRow, MonthMatrix, modifierNet, monthMatrix, perfSegments |
| `server/shared/walls.js` | 159 | 4 | 5 | -0.20 | 15 | 8 | +0.57 | 65 | 11 | 11 |  | e1 | pairKey, WAGES_WALL, wallContext, placeholders, warnedNoWalls, missingTables |
| `web/src/app/chat-handle.tsx` | 39 | 2 | 2 | +0.00 | 7 | 3 | +0.77 | 35 | 4 | 5 |  | e1 | ChatHandle, chat-handle |
| `server/shared/auth.test.js` | 2080 | 0 | 0 | +0.00 | 7 | 3 | +0.77 | 10 | 4 | 7 |  | e1 | adminReq, usersApi, wallState, APPS_RUNS, auth.test, roleState |
| `connectors/onedrive/api/graph-client.js` | 343 | 3 | 2 | +0.37 | 4 | 6 | -0.37 | 50 | 9 | 1 |  | e1 | pathOf, postGrant, searchUrl, GRAPH_BASE, filterKind, driveOwner |
| `web/src/lib/use-pathname.ts` | 29 | 6 | 5 | +0.17 | 9 | 5 | +0.54 | 26 | 8 | 3 |  | e1 | usePathname, use-pathname |
| `spheres/coord/api/read.js` | 282 | 2 | 2 | +0.00 | 13 | 6 | +0.70 | 41 | 10 | 13 |  | e1 | IN_SCOPE, listTasks, listSpaces, SCOPE_JOIN, taskSource, syncStatus |
| `connectors/awsconnect/api/sigv4.js` | 76 | 2 | 2 | +0.00 | 8 | 4 | +0.63 | 47 | 5 | 6 |  | e3 | sigv4, rfc3986, amzDate, datestamp, sha256hex, signingKey |
| `spheres/coord/api/decode.js` | 153 | 1 | 1 | +0.00 | 2 | 4 | -0.63 | 70 | 5 | 1 |  | e2 | decodeTask, lastAtName, lifecycleOf, messageName, ASSIGN_VERBS, spaceOfMessage |
| `web/src/lib/chat-store.ts` | 222 | 1 | 2 | -0.63 | 4 | 4 | +0.00 | 34 | 5 | 3 |  | e3 | headId, isRecord, setChatId, chat-store, chatThread, saveRecord |
| `spheres/reputation/ui/ReviewCard.tsx` | 113 | 2 | 2 | +0.00 | 6 | 3 | +0.63 | 25 | 4 | 4 |  | e1 | isLong, ClampText, showPlace, reviewsUrl, ReviewCard, CLAMP_CHARS |
| `connectors/googlereviews/api/import-historical.js` | 105 | 1 | 1 | +0.00 | 8 | 4 | +0.63 | 15 | 5 | 7 |  | e2 | runImport, import-historical |
| `spheres/social/ui/CampaignDelete.tsx` | 67 | 2 | 2 | +0.00 | 4 | 2 | +0.63 | 24 | 3 | 2 |  | e2 | onDeleted, CampaignDelete, CampaignDeleteButton |
| `connectors/googlereviews/api/serpapi-client.js` | 70 | 1 | 2 | -0.63 | 4 | 4 | +0.00 | 16 | 5 | 3 |  | e3 | SEARCH_URL, serpapi-client, makeSerpapiClient |
| `spheres/customer-service/api/calls.test.js` | 199 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 11 | 2 | 1 |  | e1 | TZ_ROW, totalsRow, calls.test |
| `connectors/clover/api/clover-client.js` | 137 | 1 | 2 | -0.63 | 4 | 4 | +0.00 | 14 | 6 | 3 |  | e3 | elementsOf, clover-client, makeCloverClient |
| `connectors/github/api/github-client.js` | 156 | 1 | 2 | -0.63 | 4 | 4 | +0.00 | 12 | 5 | 3 |  | e3 | USER_AGENT, encodePath, API_VERSION, resetWaitMs, github-client, isRateLimited |
| `spheres/customer-service/api/transcripts.js` | 90 | 1 | 1 | +0.00 | 2 | 4 | -0.63 | 15 | 6 | 1 |  | e2 | transcribeCall, readTranscript |
| `spheres/publicity/api/jobs.js` | 110 | 1 | 2 | -0.63 | 4 | 4 | +0.00 | 8 | 5 | 3 |  | e3 | memberFromId, buildPublicityJobs |
| `spheres/relationships/ui/views/Matches.tsx` | 321 | 1 | 1 | +0.00 | 4 | 2 | +0.63 | 5 | 3 | 4 |  | e1 | QueueRow, memberId, RowMember, buildRows, sourceLabel, evidenceLabel |
| `server/shared/manifest.test.js` | 122 | 0 | 0 | +0.00 | 4 | 2 | +0.63 | 5 | 2 | 4 |  | e1 | manifest.test |
| `server/shared/route-manifest.test.js` | 66 | 0 | 0 | +0.00 | 4 | 2 | +0.63 | 5 | 3 | 4 |  | e1 | route-manifest.test |
| `web/src/app/access-sections.ts` | 45 | 2 | 3 | -0.37 | 3 | 4 | -0.26 | 15 | 6 | 1 |  | e1 | AccessSection, accessSection, ACCESS_SECTIONS, access-sections, accessSectionFor, accessSectionsFor |
| `spheres/financial/api/walls.test.js` | 153 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 5 | 2 | 1 |  | e1 | WAGE_CODE, seedLedger, sourceType, seedJournal, admitToWages |
| `server/shared/invariants.test.js` | 142 | 0 | 0 | +0.00 | 4 | 2 | +0.63 | 4 | 3 | 4 |  | e1 | isTest, invariants.test, FOUNDING_SLUG_HOMES |
| `server/shared/schema-conformance.test.js` | 110 | 0 | 0 | +0.00 | 4 | 2 | +0.63 | 4 | 3 | 4 |  | e1 | schema-conformance.test |
| `spheres/coord/ui/views/ByPerson.tsx` | 196 | 2 | 1 | +0.63 | 2 | 2 | +0.00 | 3 | 3 | 2 |  | e1 | TaskSource, PersonTasks |
| `spheres/social/api/jobsdesc.test.js` | 237 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 3 | 2 | 1 |  | e1 | T_BI03, T_SOLO, T_AI01, T_GROUP, addMember, CONTACT_A |
| `scripts/import-meta-exports.test.mjs` | 151 | 0 | 0 | +0.00 | 2 | 1 | +0.63 | 2 | 2 | 2 |  | e1 | import-meta-exports.test |
| `connectors/spar/api/parse.test.js` | 321 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 2 | 2 | 1 |  | e1 | ROW_B, ROW_A, ROW_C, HEADER_A, HEADER_B, parse.test |
| `spheres/social/api/ai00.test.js` | 158 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 2 | 2 | 1 |  | e1 | T_NON, T_MKT, T_MISS, ai00.test, batchPersist, seedAccounts |
| `server/shared/walls.test.js` | 150 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 2 | 2 | 1 |  | e3 | seedWall, emptyConn, missingConn |
| `connectors/otter/api/bo02.test.js` | 141 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 1 | 2 | 1 |  | e1 | bo02.test, seededConn |
| `spheres/schedule/api/moves.test.js` | 246 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 1 | 2 | 1 |  | e1 | goodBody, moves.test, localHandlers |
| `spheres/social/api/bi03.test.js` | 432 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 1 | 2 | 1 |  | e1 | bi03.test, postsPage, liveMember, seedApprovedThread, seedMultiMemberThread, seedRestedMarketingThread |
| `spheres/social/api/jobrun-version.test.js` | 71 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 1 | 2 | 1 |  | e1 | jobrun-version.test |
| `server/shared/closure.test.js` | 105 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 1 | 2 | 1 |  | e1 | makeStore, publicRow, closure.test |
| `server/shared/connector-health.test.js` | 142 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 1 | 2 | 1 |  | e1 | connector-health.test |
| `server/shared/job-runs.test.js` | 144 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 1 | 2 | 1 |  | e1 | fakeDeps, RUN_BASE, job-runs.test |
| `server/shared/sync-runs.test.js` | 408 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 1 | 3 | 1 |  | e3 | gateConn, makeFakeDb, sync-runs.test, makeFrameHarness |
| `server/shared/versions.test.js` | 49 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 1 | 2 | 1 |  | e1 | versions.test |
| `scripts/import-env-credentials.mjs` | 103 | 0 | 0 | +0.00 | 1 | 2 | -0.63 | 1 | 3 | 1 |  | e1 | import-env-credentials |
| `spheres/financial/ui/letterhead.ts` | 66 | 3 | 2 | +0.37 | 3 | 4 | -0.26 | 14 | 5 | 0 |  | e2 | useTenants, TenantInfo, soleCountry, letterheadFor |
| `spheres/library/ui/ItemOverlay.tsx` | 91 | 2 | 1 | +0.63 | 2 | 2 | +0.00 | 6 | 3 | 0 |  | e1 | ItemOverlay |
| `spheres/reputation/ui/PlaceChips.tsx` | 30 | 2 | 1 | +0.63 | 2 | 2 | +0.00 | 10 | 3 | 0 |  | e1 | PlaceChips, usePlaceParam |
| `spheres/social/ui/sweep.ts` | 20 | 2 | 1 | +0.63 | 2 | 2 | +0.00 | 4 | 3 | 0 |  | e1 | dispatchSweep |
| `spheres/social/ui/useUnreadNotifier.ts` | 76 | 1 | 1 | +0.00 | 1 | 2 | -0.63 | 3 | 3 | 0 |  | e3 | useUnreadNotifier |
| `spheres/social/ui/PerformanceChart.tsx` | 281 | 1 | 1 | +0.00 | 1 | 2 | -0.63 | 5 | 3 | 0 |  | e3 | niceMax, useWidth, PerformanceChart |
| `scripts/import-otter-corpus.test.js` | 340 | 0 | 0 | +0.00 | 0 | 1 | -0.63 | 0 | 2 | 0 |  | e2 | SCHEMA_FM, BROKEN_FM, import-otter-corpus.test |
| `server/shared/tenancy.js` | 124 | 6 | 7 | -0.14 | 16 | 10 | +0.43 | 61 | 14 | 11 |  | e1 | warnMissing, groupTenants, tenantContext, creationTenant, FOUNDING_TENANT |
| `web/src/lib/chat.ts` | 254 | 2 | 3 | -0.37 | 5 | 4 | +0.20 | 43 | 5 | 3 |  | e3 | onTool, onError, onDrive, ChatSend, sendChat, probeChat |
| `server/shared/db-errors.js` | 19 | 7 | 5 | +0.31 | 8 | 6 | +0.26 | 9 | 10 | 1 |  | e1 | db-errors |
| `web/src/lib/org-identity.ts` | 103 | 3 | 3 | +0.00 | 11 | 6 | +0.55 | 20 | 8 | 9 |  | e1 | TaxRegister, org-identity, TAX_REGISTERS, taxRegisterFor, LetterheadLines, OrgIdentityFields |
| `spheres/social/ui/components.tsx` | 366 | 6 | 5 | +0.17 | 9 | 6 | +0.37 | 131 | 8 | 3 |  | e1 | ageOf, msgLine, FacetTags, dateRange, MsgPreview, CollabStat |
| `connectors/facebook/api/insights-sync.js` | 311 | 3 | 2 | +0.37 | 6 | 5 | +0.17 | 52 | 7 | 5 |  | e1 | postPk, endTime, graphId, pageIdOf, fbPostIdOf, upsertPost |
| `connectors/sonas/api/sonas-client.js` | 376 | 3 | 2 | +0.37 | 6 | 5 | +0.17 | 56 | 7 | 4 |  | e1 | WS_URL, ejsonDate, ejsonToMysql, sonas-client, EPOCH_2100_MS, EPOCH_1900_MS |
| `server/shared/credential-manifests.js` | 77 | 2 | 3 | -0.37 | 5 | 6 | -0.17 | 27 | 8 | 3 |  | e3 | manifestFor, DEFAULT_ROOT, listManifests, credential-manifests |
| `server/shared/trail.js` | 45 | 2 | 3 | -0.37 | 5 | 6 | -0.17 | 27 | 8 | 3 |  | e1 | recordWrite |
| `server/shared/runbook.js` | 68 | 4 | 4 | +0.00 | 12 | 7 | +0.49 | 51 | 9 | 8 |  | e1 | loadRunbook, jobCodeLower, extractPrompt, resolveRunbook |
| `scripts/import-otter-corpus.mjs` | 755 | 0 | 0 | +0.00 | 5 | 3 | +0.46 | 61 | 5 | 5 |  | e2 | fmDoc, mdBody, fmText, asArray, inLedger, stemDate |
| `server/shared/grants.test.js` | 318 | 0 | 0 | +0.00 | 5 | 3 | +0.46 | 16 | 4 | 5 |  | e1 | grants.test, COVERS_VECTORS, ALLOWED_VECTORS, VERB_COVER_VECTORS, TOKEN_COVER_VECTORS |
| `spheres/schedule/api/valid.js` | 30 | 4 | 3 | +0.26 | 4 | 5 | -0.20 | 21 | 8 | 0 |  | e1 | isHHMM, DATE_RE, HHMM_RE, spanDays, isISODate |
| `web/src/lib/grants.ts` | 83 | 6 | 8 | -0.26 | 7 | 8 | -0.12 | 47 | 11 | 2 |  | e3 | AuthReach, GrantVerb, GrantToken |
| `spheres/projects/api/derive.js` | 138 | 1 | 1 | +0.00 | 6 | 4 | +0.37 | 70 | 6 | 5 |  | e2 | prereqId, statusAt, statusOf, prereqsOf, wouldCycle, dependentId |
| `connectors/googlereviews/api/upsert.js` | 183 | 2 | 3 | -0.37 | 5 | 5 | +0.00 | 55 | 8 | 3 |  | e3 | rawCols, dataIds, placeSQL, placeRow, reviewRow, ownerCols |
| `server/shared/manifest.js` | 166 | 2 | 3 | -0.37 | 6 | 6 | +0.00 | 26 | 8 | 4 |  | e3 | skillsRoot, loadManifest, REQUIRED_KEYS, manifestPaths, validateManifest, scanManifestPaths |
| `server/shared/pipeline-fixture.js` | 86 | 2 | 3 | -0.37 | 5 | 5 | +0.00 | 24 | 6 | 3 |  | e1 | viewBody, VIEW_BODY, platformSql, tempTableDdl, statementFrom, setupPipelineCore |
| `spheres/social/api/stage-advance.js` | 252 | 3 | 2 | +0.37 | 5 | 5 | +0.00 | 14 | 7 | 4 |  | e1 | PK_OF, entryPass, CAMPAIGN_OF, entryPassDue, HAS_NEW_OUTBOUND, HAS_INBOUND_TEXT |
| `spheres/coord/ui/views/MeetingFollowUp.tsx` | 134 | 1 | 1 | +0.00 | 3 | 2 | +0.37 | 17 | 3 | 2 |  | e1 | meetingPath, spaceRoomUrl, composeFollowUp, MeetingFollowUp |
| `connectors/dropbox/api/dropbox-client.js` | 359 | 3 | 2 | +0.37 | 6 | 6 | +0.00 | 20 | 9 | 3 |  | e1 | API_BASE, EXT_KIND, HOME_URL, homeLink, matchMeta, parentPath |
| `server/shared/credentials.test.js` | 447 | 0 | 0 | +0.00 | 3 | 2 | +0.37 | 10 | 3 | 3 |  | e1 | hookFor, staleRow, tenantRows |
| `web/src/app/AccessApps.tsx` | 459 | 1 | 1 | +0.00 | 2 | 3 | -0.37 | 8 | 4 | 1 |  | e1 | FieldRow, RunBlock, reasonText, AccessApps, SessionRow, PRODUCT_NAME |
| `web/src/lib/interaction-context.test.ts` | 296 | 0 | 0 | +0.00 | 3 | 2 | +0.37 | 3 | 3 | 3 |  | e1 | interaction-context.test |
| `connectors/otter/api/bo01.test.js` | 169 | 0 | 0 | +0.00 | 3 | 2 | +0.37 | 3 | 2 | 3 |  | e1 | bo01.test |
| `spheres/coord/api/meetings.test.js` | 230 | 0 | 0 | +0.00 | 3 | 2 | +0.37 | 3 | 2 | 3 |  | e1 | responder, meetings.test |
| `connectors/tiktok/api/tiktok-client.js` | 134 | 3 | 2 | +0.37 | 4 | 4 | +0.00 | 9 | 5 | 1 |  | e1 | API_HOST, tokenCall, AUTH_HOST, USER_FIELDS, VIDEO_FIELDS, tiktok-client |
| `web/src/app/AccessPeople.tsx` | 513 | 1 | 1 | +0.00 | 2 | 3 | -0.37 | 4 | 4 | 1 |  | e1 | InviteRow, AccessPeople, effectiveAccess |
| `web/src/app/AccessWalls.tsx` | 249 | 1 | 1 | +0.00 | 2 | 3 | -0.37 | 4 | 4 | 1 |  | e1 | WallCard, AccessWalls |
| `agent/server.test.js` | 549 | 0 | 0 | +0.00 | 2 | 3 | -0.37 | 2 | 4 | 2 |  | e1 | signJwt, toolUse, extraEnv, ORIGIN_A, bootFeed, ORIGIN_B |
| `spheres/schedule/ui/cards.tsx` | 94 | 3 | 2 | +0.37 | 3 | 3 | +0.00 | 8 | 4 | 0 |  | e1 | timeFace, shortDate, EntryCard, PeopleGlyph |
| `connectors/instagram/api/jobs.js` | 559 | 3 | 3 | +0.00 | 11 | 8 | +0.29 | 61 | 14 | 10 |  | e2 | longId, shortPk, viewerId, DUMP_SQL, normCount, handlesOf |
| `spheres/schedule/api/almanac.js` | 296 | 2 | 2 | +0.00 | 3 | 4 | -0.26 | 45 | 6 | 2 |  | e1 | termRow, optDate, optText, MONTH_RE, entryRow, FILE_SQL |
| `web/src/app/AccessRoles.tsx` | 499 | 1 | 1 | +0.00 | 4 | 3 | +0.26 | 12 | 4 | 3 |  | e1 | onSet, SegRow, roleCell, CellPair, CellTone, RoleDrawer |
| `scripts/deploy-skills.mjs` | 93 | 0 | 0 | +0.00 | 4 | 3 | +0.26 | 6 | 4 | 4 |  | e2 | arefs, isSkillRef, deploy-skills |
| `server/shared/deepseek.js` | 52 | 2 | 2 | +0.00 | 3 | 4 | -0.26 | 18 | 5 | 1 |  | e3 | deepseek, MODEL_ID, runRunbookDeepseek |
| `spheres/coord/ui/windows.tsx` | 40 | 2 | 2 | +0.00 | 3 | 4 | -0.26 | 15 | 6 | 1 |  | e2 | isWindow, WindowChips, useWindowParam |
| `spheres/financial/ui/vocab.ts` | 68 | 2 | 2 | +0.00 | 3 | 4 | -0.26 | 13 | 6 | 1 |  | e1 | LocalName, localNameIn, VOCAB_ROUTE, useLocalName, SOURCE_LOCALE |
| `server/shared/stage-vocabulary.js` | 118 | 4 | 4 | +0.00 | 9 | 7 | +0.23 | 29 | 9 | 5 |  | e1 | subsetAllows, stage-vocabulary, buildStageVocabulary |
| `server/shared/stage-advance.js` | 323 | 5 | 5 | +0.00 | 7 | 9 | -0.23 | 30 | 13 | 3 |  | e1 | sqlDate, FLIP_UTC, frameLook, envPrefix, STAGE_GUARD, graceMinutesFor |
| `spheres/social/ui/perf-derive.ts` | 689 | 2 | 2 | +0.00 | 5 | 4 | +0.20 | 254 | 6 | 3 |  | e1 | DAY_RE, DayRow, PerfRow, SortKey, ChartRow, deltasOf |
| `spheres/coord/capture.js` | 31 | 2 | 2 | +0.00 | 4 | 5 | -0.20 | 12 | 8 | 2 |  | e2 | doneSignal, CAPTURE_REPO, OTHER_BUSINESS_PREFIX |
| `server/shared/contract-helpers.js` | 41 | 4 | 4 | +0.00 | 5 | 6 | -0.17 | 68 | 10 | 1 |  | e1 | faultReason, callerMetaUrl, contractReason, compileContract, contract-helpers |
| `server/shared/http-raw.js` | 54 | 18 | 20 | -0.10 | 20 | 20 | +0.00 | 35 | 30 | 2 |  | e1 | http-raw |
| `spheres/schedule/api/reconcile-logic.js` | 165 | 2 | 2 | +0.00 | 4 | 4 | +0.00 | 64 | 5 | 2 |  | e1 | agedOut, targetOf, listOpenMoves, matchesTarget, decidePending, parseNativeId |
| `server/shared/venue-date.js` | 64 | 6 | 6 | +0.00 | 10 | 10 | +0.00 | 54 | 14 | 4 |  | e1 | fmtDay, venueDate, venue-date, epochSeconds |
| `spheres/reputation/ui/lanes.ts` | 101 | 1 | 1 | +0.00 | 3 | 3 | +0.00 | 33 | 4 | 2 |  | e1 | LaneKpi, overTarget, deriveLanes, responseDays, negativeFirst, repliedWindowDays |
| `spheres/coord/ui/views/Meetings.tsx` | 299 | 1 | 1 | +0.00 | 2 | 2 | +0.00 | 19 | 3 | 2 |  | e1 | monthKey, setPages, setAfter, groupByMonth, PERSON_CHIPS, MeetingDetail |
| `server/shared/sql-static.js` | 408 | 3 | 3 | +0.00 | 5 | 5 | +0.00 | 41 | 7 | 2 |  | e1 | sqlRaw, cleanIdent, sql-static, matchParen, parseSchema, parseWrites |
| `spheres/social/ui/ContactDetail.tsx` | 818 | 1 | 1 | +0.00 | 3 | 3 | +0.00 | 12 | 4 | 3 |  | e1 | onPick, PostRow, onJoined, shortTime, onRemoved, mediaLabel |
| `connectors/spar/sync.js` | 175 | 0 | 0 | +0.00 | 3 | 3 | +0.00 | 8 | 5 | 3 |  | e2 | readText, listFiles |
| `spheres/schedule/ui/slots.tsx` | 30 | 1 | 1 | +0.00 | 2 | 2 | +0.00 | 10 | 3 | 1 |  | e3 | slotZones |
| `connectors/awsconnect/api/presign.js` | 34 | 2 | 2 | +0.00 | 3 | 3 | +0.00 | 12 | 4 | 1 |  | e3 | presign, presignS3Get |
| `spheres/relationships/ui/views/PersonPanel.tsx` | 334 | 1 | 1 | +0.00 | 2 | 2 | +0.00 | 9 | 3 | 1 |  | e1 | onGone, PersonPanel, ProfileStats |
| `spheres/schedule/ui/EntryEditor.tsx` | 115 | 1 | 1 | +0.00 | 2 | 2 | +0.00 | 9 | 3 | 1 |  | e1 | EntryEditor |
| `spheres/schedule/api/providers.test.js` | 426 | 0 | 0 | +0.00 | 2 | 2 | +0.00 | 3 | 3 | 2 |  | e1 | providers.test |
| `server/shared/connector-tenant.test.js` | 134 | 0 | 0 | +0.00 | 2 | 2 | +0.00 | 3 | 2 | 2 |  | e1 | withAttribution, connector-tenant.test |
| `spheres/social/ui/drafts.tsx` | 206 | 1 | 1 | +0.00 | 2 | 2 | +0.00 | 5 | 3 | 1 |  | e3 | onPatch, DraftDrawer |
| `spheres/social/ui/CampaignWizard.tsx` | 370 | 1 | 1 | +0.00 | 2 | 2 | +0.00 | 4 | 3 | 1 |  | e1 | CampaignWizard |
| `spheres/social/ui/useAutoSweep.ts` | 82 | 1 | 1 | +0.00 | 2 | 2 | +0.00 | 4 | 3 | 1 |  | e3 | SWEEP_MS, LAST_KEY, useAutoSweep, stampDispatch, lastDispatchAt |
| `server/shared/spar-pipeline.test.js` | 444 | 0 | 0 | +0.00 | 2 | 2 | +0.00 | 2 | 2 | 2 |  | e1 | STAGE_GATE, spar-pipeline.test |
| `agent/descriptions.test.js` | 126 | 0 | 0 | +0.00 | 2 | 2 | +0.00 | 2 | 2 | 2 |  | e1 | WORD_CEILING, descriptions.test, EXCEPTION_CEILING |
| `connectors/awsconnect/api/sigv4.test.js` | 52 | 0 | 0 | +0.00 | 1 | 1 | +0.00 | 1 | 2 | 1 |  | e2 | sigv4.test |
