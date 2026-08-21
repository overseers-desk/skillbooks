# Measured table — round 3

384 non-test module concepts, ranked by score (C x leak/B): sites weighted by the share of
mentioning files the reference graph never saw. 99 of them have no distinctive vocabulary
after the filter, so their B and C are not measured; their A and D still hold.

| # | module | A | D | B | C | leak | score | vocabulary sample |
|---:|---|---:|---:|---:|---:|---:|---:|---|
| 1 | `web/src/pipeline/api.ts` | 16 | 3 | 99 | 1161 | 85 | 997 | Reply,p_note,s_note,a_note,Person,r_note |
| 2 | `web/src/lib/auth.ts` | 11 | 2 | 109 | 590 | 101 | 547 | AppRun,AppUser,addedAt,addedBy,AppField,listApps |
| 3 | `spheres/relationships/ui/api.ts` | 3 | 1 | 73 | 422 | 70 | 405 | Match,Party,userId,claimId,eventId,Identity |
| 4 | `spheres/social/ui/api.ts` | 15 | 3 | 61 | 457 | 50 | 375 | Grade,sentAt,tiktok,takenAt,LastMsg,Message |
| 5 | `server/shared/datasets.js` | 3 | 0 | 48 | 388 | 45 | 364 | datasets,DATASETS,knownDataset,servedDatasets |
| 6 | `server/shared/runbook.js` | 4 | 0 | 60 | 311 | 56 | 290 | runbook,loadRunbook,jobCodeLower,extractPrompt,resolveRunbook |
| 7 | `server/shared/testdb.js` | 0 | 1 | 36 | 276 | 36 | 276 | testdb,withTxn |
| 8 | `spheres/schedule/api/providers/rezdy.js` | 1 | 1 | 72 | 275 | 71 | 271 | rezdy,GRID_SQL,deriveSlots,OCCUPANCY_SQL |
| 9 | `server/shared/auth.js` | 3 | 9 | 44 | 230 | 42 | 220 | codeStr,startMs,newCode,setPrefs,clientIp,newToken |
| 10 | `web/src/ui/boardDrag.ts` | 4 | 1 | 17 | 217 | 13 | 166 | onDrop,onLift,specFor,canDrag,fromKey,dropSpec |
| 11 | `spheres/publicity/ui/api.ts` | 3 | 2 | 54 | 168 | 51 | 159 | Coverage,created_at,addCoverage,coverageCount,CoverageInput,CoverageCount |
| 12 | `spheres/schedule/ui/api.ts` | 7 | 2 | 28 | 212 | 21 | 159 | Entry,moveId,TermRow,fromDate,MoveBody,postMove |
| 13 | `spheres/customer-service/ui/api.ts` | 1 | 0 | 11 | 175 | 10 | 159 | CallRep,CallRow,CallDay,agentId,rangOut,CallCost |
| 14 | `server/shared/sync-runs.js` | 26 | 1 | 65 | 259 | 39 | 155 | endRun,syncDue,BEAT_MS,syncBusy,beginRun,sync-runs |
| 15 | `spheres/social/ui/perf-derive.ts` | 2 | 1 | 5 | 255 | 3 | 153 | Grain,DAY_RE,DayRow,Typical,SortKey,PerfRow |
| 16 | `web/src/ui/FilterBar.tsx` | 2 | 2 | 18 | 138 | 16 | 123 | onAll,onNone,optionsOf,FilterBar,FilterCheck,FacetButton |
| 17 | `server/shared/grants.js` | 3 | 1 | 6 | 141 | 5 | 118 | needVerb,DATA_TOKEN,VERB_ORDER,parseGrants,formatToken,warnedTokens |
| 18 | `server/shared/ready.js` | 1 | 1 | 19 | 122 | 18 | 116 | freshIds,staleIds,workQueue,readyWork,makeReader,describeWork |
| 19 | `spheres/coord/ui/api.ts` | 5 | 2 | 28 | 137 | 23 | 113 | Space,Window,Meeting,sweepNow,LeaderRow,TaskState |
| 20 | `spheres/reputation/ui/api.ts` | 5 | 1 | 17 | 147 | 12 | 104 | Place,Policy,Review,avgRating,placeTitle,totalScore |
| 21 | `scripts/import-meta-exports.mjs` | 0 | 4 | 23 | 103 | 23 | 103 | winKey,mdyToIso,fileLabel,permalink,postIdCell,ownHandles |
| 22 | `web/src/lib/format.ts` | 28 | 0 | 34 | 288 | 12 | 102 | prefs,fmtParts,dateOrder,DateOrder,weekStart,fmtRegion |
| 23 | `scripts/refresh-meta-recent.mjs` | 0 | 4 | 21 | 101 | 21 | 101 | skillRef,runSkill,faultText,overseerUp,IG_HANDLES,resolveOwnPk |
| 24 | `connectors/instagram/api/shortcode.js` | 3 | 0 | 13 | 127 | 10 | 98 | shortcode,IG_ALPHABET,shortcodeToPk,pkToShortcode,shortcodeFromPermalink |
| 25 | `server/shared/spar-pipeline.js` | 5 | 4 | 39 | 105 | 34 | 92 | claimSql,memberJson,configPath,loadClaims,MEMBER_SQL,LAST_TOUCH |
| 26 | `spheres/projects/ui/api.ts` | 2 | 3 | 8 | 121 | 6 | 91 | stageAt,notedBy,setBall,LivesAt,locator,notedAt |
| 27 | `web/src/ui/atoms.tsx` | 44 | 0 | 38 | 213 | 16 | 90 | Stars,Avatar,PillTone,AvatarSize,StatusPill,CountBadge |
| 28 | `spheres/social/ui/Rolodex.tsx` | 3 | 11 | 14 | 106 | 11 | 83 | NO_STAR,onSweep,listIcon,isSoured,gridIcon,ViewKind |
| 29 | `web/src/ui/CtxMenu.tsx` | 6 | 0 | 39 | 94 | 33 | 80 | CtxSub,CtxMenu,CtxItem,viewport,CtxButton,subOffsets |
| 30 | `web/src/lib/journey.ts` | 11 | 1 | 17 | 110 | 12 | 78 | loadSeq,sphereOf,saveTail,loadTail,includeHeld,JOURNEY_CAP |
| 31 | `web/src/lib/use-api-view.ts` | 38 | 3 | 53 | 239 | 15 | 68 | paramsOf,useApiView,apiViewKey,apiViewPath,resolveRoute,use-api-view |
| 32 | `spheres/social/api/instance.js` | 0 | 3 | 20 | 66 | 20 | 66 | loadVocab,stagePassDue |
| 33 | `server/shared/job-runs.js` | 6 | 1 | 26 | 84 | 20 | 65 | runBase,job-runs,runBPersist,normalizeResolvedVersion |
| 34 | `connectors/instagram/api/insights-sync.js` | 1 | 2 | 9 | 70 | 8 | 62 | dayUtc,ownerPk,mediaPk,pollSet,fullWalk,dayBounds |
| 35 | `scripts/import-otter-corpus.mjs` | 0 | 3 | 5 | 61 | 5 | 61 | fmDoc,fmText,mdBody,asArray,inLedger,stemDate |
| 36 | `spheres/financial/ui/export.ts` | 1 | 1 | 7 | 65 | 6 | 56 | setOff,NUM_FMT,viewWord,viewLabel,sheetName,localName |
| 37 | `connectors/instagram/api/jobs.js` | 3 | 2 | 10 | 60 | 9 | 54 | longId,shortPk,viewerId,DUMP_SQL,normCount,handlesOf |
| 38 | `spheres/projects/api/derive.js` | 1 | 0 | 5 | 68 | 4 | 54 | prereqId,statusAt,statusOf,prereqsOf,wouldCycle,dependentId |
| 39 | `server/shared/credentials.js` | 24 | 4 | 38 | 145 | 14 | 53 | fieldOf,updatedBy,readToken,writeToken,setCredential,clearCredential |
| 40 | `web/src/ui/DeepLink.tsx` | 8 | 1 | 29 | 73 | 21 | 53 | DeepLink |
| 41 | `web/src/lib/view-registry.ts` | 8 | 1 | 17 | 99 | 9 | 52 | nextId,ChoiceSet,Assertion,view-registry,anchorElement,registerAnchor |
| 42 | `connectors/linkedin/api/jobs.js` | 1 | 2 | 5 | 52 | 5 | 52 | isSelf,ownerUrn,profileUrn,connectedAt,connectedUrn,validateInbox |
| 43 | `web/src/ui/ReachNote.tsx` | 30 | 3 | 43 | 169 | 13 | 51 | useReach,ReachNote |
| 44 | `connectors/xero/api/xero-client.js` | 2 | 1 | 17 | 56 | 15 | 49 | accessToken,extractList,xero-client,PRODUCT_BASES,makeXeroClient,CONNECTIONS_URL |
| 45 | `agent/tools.js` | 1 | 1 | 7 | 56 | 6 | 48 | BI_BASE,rowFault,toolNames,deriveTools,toolEntries,sessionToken |
| 46 | `web/src/app/AuthGate.tsx` | 6 | 6 | 19 | 69 | 13 | 47 | AuthCtx,AuthGate,onSignedIn,LoginScreen,AuthUpdateCtx,applyStoredPrefs |
| 47 | `connectors/awsconnect/api/upsert.js` | 0 | 1 | 3 | 47 | 3 | 47 | fmtFor,DAY_NUM,localOf,fmtCache,tsToMysql,upsertUsers |
| 48 | `web/src/ui/Board.tsx` | 7 | 4 | 16 | 82 | 9 | 46 | Strip,DragCard,DropZone,DragBoard,snapIndex,BoardProps |
| 49 | `web/src/lib/url-state.ts` | 20 | 3 | 30 | 132 | 10 | 44 | readRaw,url-state,writeParam,useUrlParam,useStringParam |
| 50 | `web/src/ui/SectionHeader.tsx` | 19 | 2 | 35 | 95 | 16 | 43 | SectionHeader |
| 51 | `web/src/lib/interaction-context.ts` | 2 | 4 | 11 | 53 | 9 | 43 | byteSize,buildView,EMPTY_EXTRAS,JOURNEY_TAIL,choiceFilters,ContextExtras |
| 52 | `connectors/facebook/api/insights-sync.js` | 3 | 1 | 6 | 52 | 5 | 43 | postPk,graphId,endTime,pageIdOf,statusType,fbPostIdOf |
| 53 | `server/shared/tenancy.js` | 6 | 1 | 16 | 61 | 11 | 42 | warnMissing,groupTenants,tenantContext,creationTenant,FOUNDING_TENANT |
| 54 | `spheres/financial/ui/fy.ts` | 1 | 2 | 3 | 63 | 2 | 42 | FYRow,fyYear,fyRows,fyLabel,fyWindow,yearLabel |
| 55 | `server/shared/db.js` | 44 | 0 | 38 | 104 | 15 | 41 | loadEnv,withWrite,savepointSeq |
| 56 | `web/src/lib/slot-store.ts` | 7 | 0 | 11 | 114 | 4 | 41 | SlotView,wakeView,wakeParam,clearSlot,slot-store,setSlotPath |
| 57 | `web/src/lib/api.ts` | 34 | 1 | 32 | 142 | 9 | 40 | apiGet,apiPost,ApiError,refusalOf |
| 58 | `web/src/ui/ParamChips.tsx` | 9 | 4 | 18 | 79 | 9 | 40 | allLabel,ParamChips,ChipOption |
| 59 | `spheres/financial/ui/matrix.ts` | 2 | 1 | 7 | 55 | 5 | 39 | perfNet,DisplayRow,MonthMatrix,monthMatrix,modifierNet,perfSegments |
| 60 | `server/shared/job-claims.js` | 2 | 0 | 12 | 46 | 10 | 38 | job-claims,ttlMinutes,intervalMinutes,sweepExpiredClaims |
| 61 | `connectors/sonas/api/sonas-client.js` | 3 | 0 | 6 | 56 | 4 | 37 | WS_URL,ejsonDate,sonas-client,ejsonToMysql,EPOCH_2100_MS,EPOCH_1900_MS |
| 62 | `spheres/schedule/ui/week.ts` | 3 | 1 | 5 | 61 | 3 | 37 | DayCell,isToday,mondayOf,todayIso,weekRange,weekCells |
| 63 | `web/src/ui/FreshnessNote.tsx` | 11 | 1 | 25 | 65 | 14 | 36 | FreshnessNote |
| 64 | `spheres/library/ui/api.ts` | 5 | 0 | 10 | 50 | 7 | 35 | Source,HitKind,SourceId,sourceOf,SearchKind,ItemResponse |
| 65 | `connectors/awsconnect/api/sigv4.js` | 2 | 0 | 8 | 47 | 6 | 35 | sigv4,rfc3986,amzDate,sha256hex,datestamp,signingKey |
| 66 | `spheres/coord/api/decode.js` | 1 | 0 | 2 | 70 | 1 | 35 | lastAtName,decodeTask,messageName,lifecycleOf,ASSIGN_VERBS,spaceOfMessage |
| 67 | `spheres/coord/api/meetings.js` | 1 | 1 | 3 | 51 | 2 | 34 | clampLimit,getMeeting,likeFragment,getTranscript,addressMeeting,searchMeetings |
| 68 | `web/src/lib/tool-labels.ts` | 1 | 0 | 8 | 38 | 7 | 33 | FALLBACK,tool-labels,activityLine,LABELLED_TOOLS |
| 69 | `connectors/googlereviews/api/upsert.js` | 2 | 1 | 5 | 55 | 3 | 33 | rawCols,dataIds,placeRow,placeSQL,reviewSQL,reviewRow |
| 70 | `spheres/relationships/api/identity.js` | 1 | 0 | 2 | 66 | 1 | 33 | sparKeys,normName,personId,igHandle,normEmail,sonasKeys |
| 71 | `web/src/ui/PersonRow.tsx` | 3 | 1 | 13 | 41 | 10 | 32 | PersonRow |
| 72 | `spheres/schedule/api/reconcile-logic.js` | 2 | 0 | 4 | 64 | 2 | 32 | agedOut,targetOf,listOpenMoves,matchesTarget,parseNativeId,decidePending |
| 73 | `connectors/spar/api/upsert.js` | 1 | 1 | 2 | 65 | 1 | 32 | clipRow,pkCount,segRows,valueRows,passStart,REPLY_COLS |
| 74 | `web/src/lib/breakpoint.ts` | 3 | 0 | 16 | 38 | 13 | 31 | breakpoint,useDesktop,DESKTOP_QUERY,DESKTOP_MIN_PX,subscribeDesktop |
| 75 | `spheres/social/ui/CampaignPipeline.tsx` | 2 | 3 | 7 | 44 | 5 | 31 | onNew,onPeople,selectedId,CampaignList,deleteAction,CampaignPipeline |
| 76 | `server/shared/click-log.js` | 1 | 0 | 15 | 32 | 14 | 30 | click-log,recordClick |
| 77 | `connectors/awsconnect/api/sync.js` | 13 | 0 | 11 | 30 | 11 | 30 | listKey,venueTz,listAll,syncCost,windowMs,syncUsers |
| 78 | `spheres/schedule/api/almanac.js` | 2 | 2 | 3 | 45 | 2 | 30 | termRow,optDate,optText,entryRow,FILE_SQL,MONTH_RE |
| 79 | `server/shared/connector-health.js` | 1 | 1 | 8 | 33 | 7 | 29 | RUN_STRIP,healthRows,recentRuns,HEALTH_KINDS,HEALTH_REASONS,connector-health |
| 80 | `spheres/coord/api/read.js` | 2 | 3 | 8 | 29 | 8 | 29 | IN_SCOPE,listTasks,taskSource,listSpaces,syncStatus,SCOPE_JOIN |
| 81 | `spheres/financial/ui/views/Labour.tsx` | 1 | 15 | 14 | 30 | 13 | 28 | Labour,pctLabel,deltaLabel,hoursLabel,hoursOrDash,moneyOrDash |
| 82 | `spheres/coord/prelink.js` | 0 | 3 | 9 | 28 | 9 | 28 | prelink,prelinkMeetings |
| 83 | `connectors/rezdy/api/upsert.js` | 1 | 1 | 6 | 34 | 5 | 28 | categoryId,voucherCode,localToMysql,storedLocalText,captureBookingChanges,upsertCategoryProducts |
| 84 | `spheres/library/api/hits.js` | 2 | 0 | 3 | 41 | 2 | 27 | Q_MAX,HIT_KINDS,isNotFound,PAGE_LIMIT,SEARCH_KINDS,EMPTY_SEARCH |
| 85 | `spheres/coord/api/instance.js` | 0 | 3 | 11 | 26 | 11 | 26 | prelink,prelinkDue,reconstructDue |
| 86 | `spheres/projects/ui/views/Gantt.tsx` | 1 | 9 | 8 | 30 | 7 | 26 | Gantt,chainOf,MsPanel,onWrite,Derived,todayUTC |
| 87 | `server/shared/closure.js` | 1 | 0 | 3 | 39 | 2 | 26 | rowFor,libRefs,storeDir,notFound,findTypeB,artifactRef |
| 88 | `web/src/ui/Overlay.tsx` | 11 | 1 | 16 | 81 | 5 | 25 | Overlay,panelClassName |
| 89 | `web/src/app/ChatPane.tsx` | 1 | 2 | 11 | 28 | 10 | 25 | ChatPane,ChatUnreachable |
| 90 | `server/shared/walls.js` | 4 | 1 | 9 | 45 | 5 | 25 | pairKey,WAGES_WALL,wallContext,warnedNoWalls,missingTables,WAGES_SOURCE_TYPES |
| 91 | `spheres/schedule/api/providers/sonas.js` | 4 | 0 | 2 | 25 | 2 | 25 | headcount,WEDDINGS_SQL,VENUE_TZ_SQL,utcSqlString,mapWeddingRow,venueTimezones |
| 92 | `spheres/financial/ui/period.ts` | 5 | 2 | 8 | 63 | 3 | 24 | Preset,fyStart,extendTo,monthsOf,shortMonth,orderRange |
| 93 | `server/shared/anthropic.js` | 2 | 2 | 13 | 27 | 11 | 23 | MODEL_IDS,anthropic,runRunbook |
| 94 | `web/src/ui/FilterRow.tsx` | 3 | 0 | 12 | 31 | 9 | 23 | FilterRow |
| 95 | `web/src/ui/SelectableCard.tsx` | 3 | 0 | 9 | 34 | 6 | 23 | openLabel,SelectableCard |
| 96 | `agent/drive-tools.js` | 1 | 0 | 8 | 26 | 7 | 23 | driveSeq,driveTool,driveTools,drive-tools,DRIVE_CODES,resolveDrive |
| 97 | `spheres/financial/ui/labour-matrix.ts` | 1 | 1 | 2 | 46 | 1 | 23 | round1,wagePct,perUnit,unitIds,unitNames,LabourDay |
| 98 | `server/shared/hash.js` | 2 | 0 | 13 | 26 | 11 | 22 | sha256 |
| 99 | `server/shared/venue-date.js` | 6 | 0 | 10 | 54 | 4 | 22 | fmtDay,venueDate,venue-date,epochSeconds |
| 100 | `server/shared/ollama.js` | 2 | 1 | 10 | 27 | 8 | 22 | ollama,runRunbookLocal |
| 101 | `web/src/ui/Chips.tsx` | 3 | 1 | 9 | 33 | 6 | 22 | ChipRow |
| 102 | `connectors/rezdy/api/rezdy-client.js` | 1 | 1 | 6 | 26 | 5 | 22 | payloadOf,rezdy-client,makeRezdyClient |
| 103 | `spheres/schedule/api/moves.js` | 1 | 5 | 4 | 30 | 3 | 22 | OPEN_SQL,INSERT_SQL,CANCEL_SQL,cancelMove,RESOLVE_SQL,requestMove |
| 104 | `connectors/spar/api/parse.js` | 1 | 0 | 2 | 45 | 1 | 22 | dateN,tsvText,asGiven,indentOf,fileStem,needsFix |
| 105 | `web/src/pipeline/ContactPanel.tsx` | 3 | 7 | 9 | 32 | 6 | 21 | Event,eventDate,NoteEditor,afterWrite,memberStage,ContactPanel |
| 106 | `web/src/app/App.tsx` | 1 | 14 | 6 | 21 | 6 | 21 | Shell,resetKey,Doorbell,NoSuchPage,accessIcon,queryClient |
| 107 | `server/shared/connector-tenant.js` | 21 | 1 | 30 | 66 | 9 | 20 | tenantOf |
| 108 | `web/src/lib/error-codes.ts` | 9 | 0 | 13 | 65 | 4 | 20 | errorText,ErrorCode,DISJUNCTIVE,localizeParams |
| 109 | `web/src/lib/clicklog.ts` | 6 | 2 | 11 | 44 | 5 | 20 | clicklog,logDeepLink,openDeepLink |
| 110 | `server/shared/contract.js` | 1 | 0 | 2 | 40 | 1 | 20 | isFunc,isString,jobProblems,reservedNameProblem,validateOwnerConfig,RESERVED_SHELL_NAMES |
| 111 | `spheres/schedule/api/config.js` | 3 | 1 | 1 | 20 | 1 | 20 | isPosInt,validateConfig |
| 112 | `spheres/financial/ui/api.ts` | 9 | 2 | 10 | 47 | 4 | 19 | PLRow,exGst,PLSource,LabourRow,prevExGst,ProductRow |
| 113 | `spheres/coord/api/jobs-a.js` | 1 | 3 | 9 | 20 | 8 | 18 | jobs-a,entityRows,buildMeetingJobs |
| 114 | `spheres/social/ui/ContactDetail.tsx` | 1 | 9 | 8 | 20 | 7 | 18 | onPick,PostRow,onJoined,onRemoved,shortTime,StarPicker |
| 115 | `spheres/schedule/api/providers/local.js` | 4 | 0 | 5 | 30 | 3 | 18 | toMin,shiftEnd,MOVE_SQL,getEntry |
| 116 | `spheres/coord/ui/views/Meetings.tsx` | 1 | 10 | 3 | 18 | 3 | 18 | monthKey,setAfter,setPages,Transcript,PERSON_CHIPS,groupByMonth |
| 117 | `spheres/financial/api/read.js` | 1 | 7 | 3 | 18 | 3 | 18 | rentRow,SEG_CAT,putCell,sectionOf,sonasRows,rezdyRows |
| 118 | `spheres/social/api/performance.js` | 1 | 1 | 3 | 27 | 2 | 18 | igType,fbType,ownPks,igPosts,fbPosts,monthOf |
| 119 | `connectors/otter/api/jobs.js` | 2 | 2 | 1 | 18 | 1 | 18 | ACCOUNT_ID,recordingRow,UPSERT_CHUNK,validateList,validateFetch,UPSERT_RECORDINGS_SQL |
| 120 | `web/src/ui/GroupedList.tsx` | 3 | 1 | 10 | 24 | 7 | 17 | renderBody,GroupedList |
| 121 | `web/src/app/ChatAssistant.tsx` | 0 | 12 | 9 | 17 | 9 | 17 | DOCK_KEY,UserText,dockIcon,ToolLine,floatIcon,PanelMode |
| 122 | `spheres/social/ui/cards.tsx` | 4 | 6 | 8 | 34 | 4 | 17 | onFunnel,inCampaign,openMenuItems,campaignNames |
| 123 | `server/shared/manifest.js` | 2 | 0 | 6 | 26 | 4 | 17 | skillsRoot,loadManifest,REQUIRED_KEYS,manifestPaths,validateManifest,scanManifestPaths |
| 124 | `spheres/schedule/ui/ConfirmMove.tsx` | 1 | 3 | 4 | 23 | 3 | 17 | onConfirm,ConfirmMove |
| 125 | `server/shared/stage-vocabulary.js` | 4 | 0 | 9 | 29 | 5 | 16 | subsetAllows,stage-vocabulary,buildStageVocabulary |
| 126 | `web/src/lib/locale.ts` | 3 | 2 | 6 | 32 | 3 | 16 | regionIn,formatLocale,ES_419_REGIONS,activateLocale,ZH_HANT_REGIONS,ZH_HANS_REGIONS |
| 127 | `server/shared/credential-manifests.js` | 2 | 0 | 5 | 27 | 3 | 16 | manifestFor,DEFAULT_ROOT,listManifests,credential-manifests |
| 128 | `server/shared/trail.js` | 2 | 0 | 5 | 27 | 3 | 16 | recordWrite |
| 129 | `server/shared/sql-static.js` | 3 | 0 | 5 | 41 | 2 | 16 | IDENT,sqlRaw,sql-static,cleanIdent,matchParen,parseSchema |
| 130 | `web/src/ui/HoverTip.tsx` | 1 | 0 | 7 | 16 | 6 | 14 | HoverTip |
| 131 | `server/shared/contract-helpers.js` | 4 | 0 | 5 | 68 | 1 | 14 | faultReason,callerMetaUrl,contractReason,compileContract,contract-helpers |
| 132 | `server/shared/pipeline-fixture.js` | 2 | 1 | 5 | 24 | 3 | 14 | viewBody,VIEW_BODY,platformSql,tempTableDdl,statementFrom,setupPipelineCore |
| 133 | `spheres/library/ui/SearchBar.tsx` | 2 | 7 | 4 | 27 | 2 | 14 | setText,SearchBar,SETTLE_MS,useAnyReach,useQueryParam,useSelectedSources |
| 134 | `spheres/reputation/ui/lanes.ts` | 1 | 1 | 2 | 28 | 1 | 14 | Lanes,LaneKpi,overTarget,deriveLanes,responseDays,negativeFirst |
| 135 | `connectors/xero/api/upsert.js` | 1 | 1 | 2 | 28 | 1 | 14 | mysqlDt,LINE_SQL,LINE_COLS,xeroDateMs,TRACKING_SQL,TRACKING_COLS |
| 136 | `web/src/lib/grants.ts` | 6 | 0 | 7 | 47 | 2 | 13 | AuthReach,GrantVerb,GrantToken |
| 137 | `server/shared/stage-advance.js` | 5 | 6 | 7 | 30 | 3 | 13 | sqlDate,FLIP_UTC,envPrefix,frameLook,STAGE_GUARD,graceMinutesFor |
| 138 | `web/src/app/chat-handle.tsx` | 2 | 1 | 5 | 21 | 3 | 13 | ChatHandle,chat-handle |
| 139 | `web/src/pipeline/StagesEditor.tsx` | 2 | 4 | 5 | 22 | 3 | 13 | StageRow,onRemove,StagesEditor |
| 140 | `connectors/deputy/api/upsert.js` | 1 | 1 | 1 | 13 | 1 | 13 | dateOnly,epochToMysql |
| 141 | `web/src/ui/useCardSelection.ts` | 3 | 1 | 9 | 18 | 6 | 12 | groupFor,ClickLike,CardGestures,CardSelection,useCardSelection |
| 142 | `spheres/financial/ui/views/ProfitAndLoss.tsx` | 1 | 19 | 6 | 14 | 5 | 12 | NetRow,parseSrc,segCount,monthNets,Statement,dashBelow |
| 143 | `connectors/deputy/api/deputy-client.js` | 1 | 1 | 5 | 15 | 4 | 12 | deputy-client,makeDeputyClient |
| 144 | `spheres/schedule/ui/views/Pending.tsx` | 1 | 7 | 4 | 12 | 4 | 12 | MoveRow,canWrite |
| 145 | `connectors/googlereviews/api/serpapi-client.js` | 1 | 1 | 4 | 16 | 3 | 12 | SEARCH_URL,serpapi-client,makeSerpapiClient |
| 146 | `connectors/onedrive/api/graph-client.js` | 3 | 2 | 4 | 50 | 1 | 12 | pathOf,postGrant,searchUrl,driveOwner,GRAPH_BASE,filterKind |
| 147 | `spheres/social/api/stage-advance.js` | 3 | 4 | 5 | 14 | 4 | 11 | PK_OF,entryPass,CAMPAIGN_OF,entryPassDue,HAS_INBOUND_TEXT,selectEntryReady |
| 148 | `spheres/coord/ui/views/MeetingFollowUp.tsx` | 1 | 5 | 3 | 17 | 2 | 11 | meetingPath,spaceRoomUrl,composeFollowUp,MeetingFollowUp |
| 149 | `connectors/tiktok/api/insights-sync.js` | 1 | 2 | 3 | 17 | 2 | 11 | openId,videoRow,unixToVenue,upsertVideo,unixSeconds,saveTokenFile |
| 150 | `server/shared/chat.js` | 1 | 3 | 3 | 17 | 2 | 11 | handleChat,toolRoutes |
| 151 | `web/src/pipeline/CampaignBoard.tsx` | 1 | 7 | 1 | 11 | 1 | 11 | strayColumns,boardColumns,offFunnelColumns |
| 152 | `server/shared/secret-box.js` | 2 | 0 | 8 | 14 | 6 | 10 | IV_LEN,TAG_LEN,plaintext,secret-box |
| 153 | `connectors/dropbox/api/dropbox-client.js` | 3 | 2 | 6 | 20 | 3 | 10 | EXT_KIND,API_BASE,HOME_URL,homeLink,matchMeta,parentPath |
| 154 | `spheres/social/ui/PeopleSection.tsx` | 1 | 12 | 4 | 13 | 3 | 10 | parseOff,parseQuery,pkFromPath,desktopLike,STARS_CODEC,parseCollab |
| 155 | `connectors/clover/api/clover-client.js` | 1 | 1 | 4 | 14 | 3 | 10 | elementsOf,clover-client,makeCloverClient |
| 156 | `spheres/projects/api/read.js` | 1 | 7 | 3 | 10 | 3 | 10 | slugOk,livesAt,badSlug,postLink,projectId,noProject |
| 157 | `spheres/financial/ui/window.ts` | 1 | 1 | 2 | 20 | 1 | 10 | filterRows,OptionalSource,OPTIONAL_SOURCES |
| 158 | `connectors/deputy/api/sync.js` | 1 | 0 | 2 | 10 | 2 | 10 | maxId,maxMs,floorSec,sinceText,syncIncremental |
| 159 | `spheres/coord/api/jobs.js` | 1 | 2 | 2 | 20 | 1 | 10 | threadKey,replayLifecycle,LIFECYCLE_STATUS,reconstructTasks |
| 160 | `web/src/lib/use-pathname.ts` | 6 | 2 | 9 | 26 | 3 | 9 | usePathname,use-pathname |
| 161 | `agent/system-prompt.js` | 1 | 0 | 9 | 10 | 8 | 9 | system-prompt |
| 162 | `spheres/social/api/read.js` | 1 | 7 | 5 | 9 | 5 | 9 | ownPk,draftRow,isMember,actorFor,unpackMsg,dismissDm |
| 163 | `connectors/github/api/github-client.js` | 1 | 1 | 4 | 12 | 3 | 9 | USER_AGENT,encodePath,API_VERSION,resetWaitMs,isRateLimited,github-client |
| 164 | `server/shared/model-api.js` | 1 | 2 | 4 | 12 | 3 | 9 | model-api,runRunbookApi |
| 165 | `spheres/library/api/read.js` | 1 | 4 | 1 | 9 | 1 | 9 | itemRoute,defaultLog,searchRoute,buildHandleApi |
| 166 | `spheres/schedule/reconcile.js` | 0 | 7 | 1 | 9 | 1 | 9 | CLOSE_SQL,STALE_SQL,reconcilePass |
| 167 | `web/src/lib/org-identity.ts` | 3 | 1 | 5 | 14 | 3 | 8 | TaxRegister,org-identity,TAX_REGISTERS,taxRegisterFor,LetterheadLines,composeLetterhead |
| 168 | `server/app.js` | 0 | 16 | 5 | 8 | 5 | 8 | _mods,readGate,relToRepo,adminOnly,checkAuth,spawnSteps |
| 169 | `web/src/lib/assistant-runtime.ts` | 1 | 7 | 4 | 11 | 3 | 8 | Frame,ackedSeq,onChatId,frameQueue,lastUserText,restoreChatId |
| 170 | `spheres/publicity/ui/CoverageSection.tsx` | 2 | 3 | 4 | 17 | 2 | 8 | onAdded,coverageBadge,coverageSection,CoverageSection |
| 171 | `web/src/lib/chat-store.ts` | 1 | 0 | 3 | 12 | 2 | 8 | headId,isRecord,setChatId,chatThread,saveRecord,loadRecord |
| 172 | `spheres/customer-service/api/transcripts.js` | 1 | 3 | 2 | 15 | 1 | 8 | transcribeCall,readTranscript |
| 173 | `spheres/schedule/api/read.js` | 1 | 10 | 2 | 8 | 2 | 8 | metaRoute,slotsRoute,rangeRoute,ghostEntry,upsertEntry,pendingShape |
| 174 | `server/shared/versions.js` | 1 | 0 | 2 | 15 | 1 | 8 | latestRow,commitSha,decideAppend |
| 175 | `server/shared/access.js` | 1 | 2 | 1 | 8 | 1 | 8 | routeOf,emptyAnswer,missingRefs |
| 176 | `connectors/awsconnect/api/aws-client.js` | 1 | 2 | 4 | 9 | 3 | 7 | aws-client,makeAwsClient |
| 177 | `spheres/reputation/ui/ReviewCard.tsx` | 2 | 5 | 3 | 22 | 1 | 7 | isLong,ClampText,showPlace,ReviewCard,reviewsUrl,CLAMP_CHARS |
| 178 | `spheres/social/ui/CampaignDelete.tsx` | 2 | 3 | 3 | 21 | 1 | 7 | onDeleted,CampaignDelete,CampaignDeleteButton |
| 179 | `web/src/lib/drive.ts` | 1 | 8 | 2 | 14 | 1 | 7 | slotOf,DriveView,DriveEvent,driveSplit,driveFilter,AGENT_ACTOR |
| 180 | `connectors/clover/api/upsert.js` | 1 | 1 | 2 | 7 | 2 | 7 | lineMods,sumCents,msToLocal,lineTaxes,lineDiscounts |
| 181 | `web/src/lib/view-scope.ts` | 11 | 0 | 13 | 40 | 2 | 6 | useSlot,ViewScope,view-scope |
| 182 | `web/src/app/PrefsPanel.tsx` | 1 | 6 | 5 | 8 | 4 | 6 | ENDONYM,PrefsPanel,DATE_SAMPLE |
| 183 | `connectors/googlechat/api/chat-client.js` | 1 | 1 | 5 | 7 | 4 | 6 | chat-client,makeChatClient |
| 184 | `spheres/coord/capture.js` | 2 | 0 | 4 | 12 | 2 | 6 | doneSignal,CAPTURE_REPO,OTHER_BUSINESS_PREFIX |
| 185 | `spheres/publicity/api/jobs.js` | 1 | 3 | 4 | 8 | 3 | 6 | memberFromId,buildPublicityJobs |
| 186 | `scripts/deploy-skills.mjs` | 0 | 3 | 4 | 6 | 4 | 6 | arefs,isSkillRef,deploy-skills |
| 187 | `connectors/googlereviews/api/sync.js` | 1 | 1 | 3 | 6 | 3 | 6 | isoDate,markRun,reviewId,syncPlace,loadPlaces,searchesLast30d |
| 188 | `server/shared/deepseek.js` | 2 | 2 | 3 | 18 | 1 | 6 | MODEL_ID,deepseek,runRunbookDeepseek |
| 189 | `spheres/customer-service/api/calls.js` | 1 | 2 | 2 | 12 | 1 | 6 | costOf,heatOf,repsOf,daysOf,todayIn,hoursOf |
| 190 | `spheres/customer-service/api/read.js` | 1 | 5 | 1 | 6 | 1 | 6 | DAYS_MAX,CAL_DATE,callsParams |
| 191 | `server/shared/events.js` | 1 | 0 | 1 | 6 | 1 | 6 | createDoorbell |
| 192 | `web/src/app/sphere.ts` | 18 | 0 | 19 | 51 | 2 | 5 | Sphere,NavItem |
| 193 | `web/src/app/match.ts` | 6 | 1 | 6 | 29 | 1 | 5 | activeNav,atAppRoot,activeSphere |
| 194 | `scripts/stage-flip-harness.mjs` | 0 | 5 | 5 | 5 | 5 | 5 | DEEPSEEK,stage-flip-harness |
| 195 | `spheres/relationships/ui/views/Matches.tsx` | 1 | 6 | 4 | 5 | 4 | 5 | QueueRow,memberId,RowMember,buildRows,sourceLabel,evidenceLabel |
| 196 | `web/src/app/access-sections.ts` | 2 | 1 | 3 | 15 | 1 | 5 | AccessSection,accessSection,access-sections,ACCESS_SECTIONS,accessSectionFor,accessSectionsFor |
| 197 | `web/src/lib/chat-starters.ts` | 1 | 0 | 3 | 8 | 2 | 5 | BY_SPHERE,chat-starters,STARTER_SPHERES |
| 198 | `spheres/social/ui/PerformanceSection.tsx` | 1 | 12 | 3 | 8 | 2 | 5 | Scope,onSort,SortTh,labelOf,DeltaChip,FIRST_SLICE |
| 199 | `server/shared/http-json.js` | 1 | 1 | 3 | 8 | 2 | 5 | http-json |
| 200 | `spheres/schedule/ui/slots.tsx` | 1 | 2 | 2 | 10 | 1 | 5 | slotZones |
| 201 | `connectors/googlechat/api/sync.js` | 1 | 1 | 1 | 5 | 1 | 5 | nowIso,floorIso,syncSpace,dumpSpaces,persistPage,upsertSpaces |
| 202 | `connectors/square/api/upsert.js` | 1 | 1 | 1 | 5 | 1 | 5 | isoToLocal |
| 203 | `spheres/publicity/api/read.js` | 1 | 3 | 1 | 5 | 1 | 5 | buildApi,coverageList,coverageCounts |
| 204 | `server/shared/http-raw.js` | 18 | 0 | 20 | 35 | 2 | 4 | http-raw |
| 205 | `web/src/lib/navigate.ts` | 8 | 3 | 4 | 8 | 2 | 4 | closeSecondary |
| 206 | `spheres/financial/ui/PeriodPicker.tsx` | 3 | 2 | 4 | 14 | 1 | 4 | atDefault,PeriodPicker |
| 207 | `web/src/lib/chat.ts` | 2 | 4 | 3 | 12 | 1 | 4 | onTool,onDrive,onError,sendChat,ChatSend,probeChat |
| 208 | `spheres/financial/ui/vocab.ts` | 2 | 1 | 3 | 13 | 1 | 4 | LocalName,localNameIn,VOCAB_ROUTE,useLocalName,SOURCE_LOCALE |
| 209 | `connectors/awsconnect/api/presign.js` | 2 | 1 | 3 | 12 | 1 | 4 | presign,presignS3Get |
| 210 | `web/src/ui/highlight.ts` | 1 | 3 | 2 | 7 | 1 | 4 | highlightAnchor |
| 211 | `web/src/app/AccessApps.tsx` | 1 | 4 | 2 | 8 | 1 | 4 | FieldRow,RunBlock,SessionRow,reasonText,AccessApps,PRODUCT_NAME |
| 212 | `spheres/reputation/ui/views/AllReviews.tsx` | 1 | 7 | 2 | 8 | 1 | 4 | AllReviews |
| 213 | `spheres/schedule/ui/EntryEditor.tsx` | 1 | 2 | 2 | 9 | 1 | 4 | EntryEditor |
| 214 | `spheres/customer-service/api/policy.js` | 1 | 0 | 1 | 4 | 1 | 4 | loadPolicy |
| 215 | `web/src/lib/useDoorbell.ts` | 1 | 0 | 3 | 5 | 2 | 3 | useDoorbell |
| 216 | `web/src/app/AccessRoles.tsx` | 1 | 4 | 3 | 5 | 2 | 3 | onSet,SegRow,roleCell,CellTone,CellPair,subsetNote |
| 217 | `spheres/coord/ui/views/ByPerson.tsx` | 2 | 10 | 3 | 8 | 1 | 3 | ByPerson,TaskSource,PersonTasks |
| 218 | `spheres/schedule/ui/views/Almanac.tsx` | 1 | 9 | 3 | 3 | 3 | 3 | Month,dayOf,Legend,termTag,CAT_WORD,windowOf |
| 219 | `spheres/social/api/jobs.js` | 1 | 4 | 3 | 4 | 2 | 3 | GATE_BATCH,CLEAN_HEALTH,buildCrmJobs,anyMarketing,truncateLines,threadMembers |
| 220 | `web/src/lib/gesture-state.ts` | 1 | 1 | 2 | 6 | 1 | 3 | gesture-state,useGestureState |
| 221 | `web/src/lib/download.ts` | 1 | 0 | 2 | 6 | 1 | 3 | saveBlob |
| 222 | `connectors/square/api/square-client.js` | 1 | 1 | 2 | 6 | 1 | 3 | square-client,SQUARE_VERSION,makeSquareClient |
| 223 | `server/shared/party.js` | 1 | 3 | 2 | 3 | 2 | 3 | claimKey,postClaim,liveClaims,postRetire,jsonEmails,listParties |
| 224 | `connectors/tiktok/api/tiktok-client.js` | 3 | 1 | 4 | 9 | 1 | 2 | API_HOST,AUTH_HOST,tokenCall,USER_FIELDS,VIDEO_FIELDS,tiktok-client |
| 225 | `web/src/lib/overseer.ts` | 2 | 1 | 3 | 5 | 1 | 2 | probeOverseer,overseerSecret |
| 226 | `web/src/pipeline/Roster.tsx` | 3 | 10 | 3 | 3 | 2 | 2 | isDue,rowBadges |
| 227 | `web/src/app/AccessPeople.tsx` | 1 | 4 | 2 | 4 | 1 | 2 | InviteRow,AccessPeople,effectiveAccess |
| 228 | `web/src/app/AccessWalls.tsx` | 1 | 3 | 2 | 4 | 1 | 2 | WallCard,AccessWalls |
| 229 | `web/src/ui/SearchInput.tsx` | 1 | 0 | 2 | 4 | 1 | 2 | SearchInput |
| 230 | `spheres/social/ui/CampaignWizard.tsx` | 1 | 8 | 2 | 4 | 1 | 2 | CampaignWizard |
| 231 | `spheres/social/ui/useAutoSweep.ts` | 1 | 2 | 2 | 4 | 1 | 2 | SWEEP_MS,LAST_KEY,useAutoSweep,stampDispatch,lastDispatchAt |
| 232 | `spheres/financial/api/policy.js` | 1 | 0 | 2 | 4 | 1 | 2 | dealsClaims,frozenClaims,claimedDealsCampaigns |
| 233 | `agent/server.js` | 0 | 5 | 2 | 2 | 2 | 2 | newTurn,TLS_KEY,BODY_CAP,TLS_CERT,logDetail,logRequest |
| 234 | `server/shared/db-errors.js` | 7 | 0 | 8 | 9 | 1 | 1 | db-errors |
| 235 | `connectors/clover/api/sync.js` | 1 | 0 | 1 | 1 | 1 | 1 | syncOrders,localZoneOf,watermarkMs |
| 236 | `scripts/import-env-credentials.mjs` | 0 | 7 | 1 | 1 | 1 | 1 | import-env-credentials |
| 237 | `spheres/social/ui/components.tsx` | 6 | 4 | 6 | 66 | 0 | 0 | ageOf,msgLine,dateRange,FacetTags,CollabStat,MsgPreview |
| 238 | `spheres/schedule/api/valid.js` | 4 | 0 | 4 | 21 | 0 | 0 | isHHMM,HHMM_RE,DATE_RE,spanDays,isISODate |
| 239 | `spheres/financial/ui/letterhead.ts` | 3 | 3 | 3 | 14 | 0 | 0 | Letterhead,useTenants,TenantInfo,soleCountry,letterheadFor |
| 240 | `spheres/library/ui/Results.tsx` | 3 | 6 | 3 | 12 | 0 | 0 | Cursor,fmtSize,MediaGrid,KindGlyph,kindLabel,reachLabel |
| 241 | `spheres/schedule/ui/cards.tsx` | 3 | 3 | 3 | 8 | 0 | 0 | timeFace,EntryCard,shortDate,PeopleGlyph |
| 242 | `web/src/lib/use-anchor.ts` | 2 | 2 | 2 | 8 | 0 | 0 | useAnchor,use-anchor |
| 243 | `web/src/lib/stream.ts` | 2 | 0 | 2 | 16 | 0 | 0 | readSse,onFrame,postSse,isAbort,SseFrame,StreamAuth |
| 244 | `web/src/app/AccessGrants.tsx` | 2 | 2 | 2 | 18 | 0 | 0 | refOf,ownToken,GrantCell,ownExport,roleCover,cellVerbs |
| 245 | `spheres/coord/ui/windows.tsx` | 2 | 3 | 2 | 8 | 0 | 0 | isWindow,WindowChips,useWindowParam |
| 246 | `spheres/library/ui/ItemOverlay.tsx` | 2 | 7 | 2 | 6 | 0 | 0 | ItemOverlay |
| 247 | `spheres/reputation/ui/PlaceChips.tsx` | 2 | 4 | 2 | 10 | 0 | 0 | PlaceChips,usePlaceParam |
| 248 | `spheres/social/ui/sweep.ts` | 2 | 1 | 2 | 4 | 0 | 0 | dispatchSweep |
| 249 | `server/shared/model-retry.js` | 2 | 0 | 2 | 8 | 0 | 0 | model-retry,sendWithRetry,FIVEXX_BACKOFF_MS |
| 250 | `web/src/app/chat-icon.tsx` | 1 | 0 | 1 | 4 | 0 | 0 | chatIcon,chat-icon |
| 251 | `web/src/app/AccessTenants.tsx` | 1 | 6 | 1 | 3 | 0 | 0 | OrgRow,OrgDrawer,AccessTenants |
| 252 | `spheres/relationships/ui/views/PersonPanel.tsx` | 1 | 6 | 1 | 7 | 0 | 0 | onGone,PersonPanel,ProfileStats |
| 253 | `spheres/reputation/ui/views/NeedsReply.tsx` | 1 | 10 | 1 | 4 | 0 | 0 | NeedsReply |
| 254 | `spheres/social/ui/drafts.tsx` | 1 | 6 | 1 | 3 | 0 | 0 | onPatch,DraftDrawer |
| 255 | `spheres/social/ui/CampaignsSection.tsx` | 1 | 10 | 1 | 4 | 0 | 0 | CampRoute,routeFromPath,CampaignsSection |
| 256 | `spheres/social/ui/useUnreadNotifier.ts` | 1 | 2 | 1 | 3 | 0 | 0 | useUnreadNotifier |
| 257 | `spheres/social/ui/PerformanceChart.tsx` | 1 | 3 | 1 | 5 | 0 | 0 | niceMax,useWidth,PerformanceChart |
| 258 | `connectors/googlereviews/api/import-historical.js` | 1 | 1 | 1 | 2 | 0 | 0 | runImport |
| 259 | `spheres/projects/api/statements.js` | 1 | 0 | 1 | 11 | 0 | 0 | clearBall,updateBall,deleteLink,upsertLink,insertEvent,upsertProject |
| 260 | `spheres/social/api/statements.js` | 2 | 0 | 1 | 2 | 0 | 0 | insertSubset |
| 261 | `agent/transcribe.js` | 1 | 0 | 1 | 4 | 0 | 0 | dialogueOf,MAX_AUDIO_BYTES,transcribeEnabled,transcribeChannel,transcribeAuthorized |
| 262 | `web/src/app/spheres.ts` | 2 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 263 | `web/src/app/Access.tsx` | 1 | 11 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 264 | `web/src/main.tsx` | 0 | 2 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 265 | `web/src/vite-env.d.ts` | 1 | 0 | 0 | 0 | 0 | 0 | vite-env.d |
| 266 | `web/src/pipeline/Campaigns.tsx` | 3 | 8 | 0 | 0 | 0 | 0 | CampaignCard |
| 267 | `spheres/coord/ui/views/Board.tsx` | 1 | 10 | 0 | 0 | 0 | 0 | columnOf |
| 268 | `spheres/coord/ui/sphere.tsx` | 0 | 4 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 269 | `spheres/customer-service/ui/views/Calls.tsx` | 1 | 11 | 0 | 0 | 0 | 0 | hadOne,sliceFor,foldDays,LOG_SLICE,foldRepDays,TenantBlock |
| 270 | `spheres/customer-service/ui/sphere.tsx` | 0 | 2 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 271 | `spheres/financial/ui/views/Products.tsx` | 1 | 13 | 0 | 0 | 0 | 0 | MoveChip,CHANNEL_NAME |
| 272 | `spheres/financial/ui/views/People.tsx` | 1 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 273 | `spheres/financial/ui/views/Deals.tsx` | 1 | 4 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 274 | `spheres/financial/ui/sphere.tsx` | 0 | 6 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 275 | `spheres/library/ui/views/Media.tsx` | 1 | 6 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 276 | `spheres/library/ui/views/Documents.tsx` | 1 | 6 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 277 | `spheres/library/ui/sphere.tsx` | 0 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 278 | `spheres/partnership/ui/api.ts` | 2 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 279 | `spheres/partnership/ui/views/Roster.tsx` | 1 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 280 | `spheres/partnership/ui/views/Campaigns.tsx` | 1 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 281 | `spheres/partnership/ui/sphere.tsx` | 0 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 282 | `spheres/projects/ui/views/Portfolio.tsx` | 1 | 12 | 0 | 0 | 0 | 0 | ProjectCard,PortfolioBoard |
| 283 | `spheres/projects/ui/sphere.tsx` | 0 | 2 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 284 | `spheres/publicity/ui/views/Roster.tsx` | 1 | 4 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 285 | `spheres/publicity/ui/views/Campaigns.tsx` | 1 | 4 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 286 | `spheres/publicity/ui/sphere.tsx` | 0 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 287 | `spheres/relationships/ui/views/People.tsx` | 1 | 10 | 0 | 0 | 0 | 0 | handleOf,stagePills,subtitleOf,presenceMarks,SOURCE_OPTIONS |
| 288 | `spheres/relationships/ui/sphere.tsx` | 0 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 289 | `spheres/reputation/ui/sphere.tsx` | 0 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 290 | `spheres/schedule/ui/views/Week.tsx` | 1 | 14 | 0 | 0 | 0 | 0 | ISO_DAY,draftOf,parseWeek,rangeLabel,serializeWeek,PendingConfirm |
| 291 | `spheres/schedule/ui/sphere.tsx` | 0 | 4 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 292 | `spheres/social/ui/CampaignBoard.tsx` | 1 | 16 | 0 | 0 | 0 | 0 | onReview,DraftChip,MemberCard |
| 293 | `spheres/social/ui/sphere.tsx` | 0 | 4 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 294 | `connectors/awsconnect/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 295 | `connectors/awsconnect/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 296 | `connectors/awsconnect/sync.js` | 0 | 5 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 297 | `connectors/clover/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 298 | `connectors/clover/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 299 | `connectors/clover/sync.js` | 0 | 7 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 300 | `connectors/deputy/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 301 | `connectors/deputy/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 302 | `connectors/deputy/sync.js` | 0 | 7 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 303 | `connectors/dropbox/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 304 | `connectors/dropbox/api/consent.js` | 0 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 305 | `connectors/dropbox/api/probe.js` | 0 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 306 | `connectors/facebook/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 307 | `connectors/facebook/api/graph-client.js` | 1 | 1 | 0 | 0 | 0 | 0 | POST_FIELDS |
| 308 | `connectors/facebook/insights-sync.js` | 0 | 6 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 309 | `connectors/github/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 310 | `connectors/github/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 | subscriptionCount |
| 311 | `connectors/github/api/formats.js` | 1 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 312 | `connectors/github/api/sync.js` | 1 | 0 | 0 | 0 | 0 | 0 | loadShas,touchFile,upsertFile |
| 313 | `connectors/github/sync.js` | 0 | 7 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 314 | `connectors/googlechat/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 315 | `connectors/googlechat/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 316 | `connectors/googlechat/sync.js` | 0 | 6 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 317 | `connectors/googlereviews/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 318 | `connectors/googlereviews/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 319 | `connectors/googlereviews/import-historical.js` | 0 | 4 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 320 | `connectors/googlereviews/sync.js` | 0 | 6 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 321 | `connectors/instagram/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 322 | `connectors/instagram/api/graph-client.js` | 1 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 323 | `connectors/instagram/insights-sync.js` | 0 | 7 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 324 | `connectors/instagram/jobs.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 325 | `connectors/linkedin/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 326 | `connectors/linkedin/jobs.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 327 | `connectors/linkedin/api/memdb.js` | 0 | 0 | 0 | 0 | 0 | 0 | rowKey |
| 328 | `connectors/onedrive/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 329 | `connectors/onedrive/api/consent.js` | 0 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 330 | `connectors/onedrive/api/probe.js` | 0 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 331 | `connectors/otter/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 332 | `connectors/otter/jobs.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 333 | `connectors/otter/api/memdb.js` | 0 | 0 | 0 | 0 | 0 | 0 | COALESCE_COLS |
| 334 | `connectors/rezdy/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 335 | `connectors/rezdy/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 336 | `connectors/rezdy/api/sync.js` | 1 | 0 | 0 | 0 | 0 | 0 | syncPerCategory |
| 337 | `connectors/rezdy/sync.js` | 0 | 7 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 338 | `connectors/sonas/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 339 | `connectors/sonas/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 340 | `connectors/sonas/api/upsert.js` | 1 | 2 | 0 | 0 | 0 | 0 | captureEventChanges |
| 341 | `connectors/sonas/api/sync.js` | 1 | 0 | 0 | 0 | 0 | 0 | syncPub,syncTabular,syncTabularDetail |
| 342 | `connectors/sonas/sync.js` | 0 | 7 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 343 | `connectors/spar/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 344 | `connectors/spar/sync.js` | 0 | 4 | 0 | 0 | 0 | 0 | readText,listFiles |
| 345 | `connectors/square/import.js` | 0 | 4 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 346 | `connectors/tiktok/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 347 | `connectors/tiktok/insights-sync.js` | 0 | 7 | 0 | 0 | 0 | 0 | TOKEN_FILE |
| 348 | `connectors/tiktok/api/auth-bootstrap.js` | 0 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 349 | `connectors/xero/credentials.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 350 | `connectors/xero/hook.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 351 | `connectors/xero/api/sync.js` | 1 | 1 | 0 | 0 | 0 | 0 | syncSettings,OFFSET_CHUNK,syncPaginated,newWatermarkMs,syncOffsetWalk,setOffsetCursor |
| 352 | `connectors/xero/sync.js` | 0 | 6 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 353 | `connectors/xero/api/auth-bootstrap.js` | 0 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 354 | `spheres/coord/reconstruct.js` | 0 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 355 | `server/shared/error-codes.js` | 5 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 356 | `server/shared/dispatch.js` | 12 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 357 | `server/shared/freshness.js` | 5 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 358 | `spheres/customer-service/api/instance.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 359 | `spheres/financial/api/statements.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 360 | `spheres/financial/api/instance.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 361 | `spheres/library/api/providers.js` | 1 | 3 | 0 | 0 | 0 | 0 | appCreds |
| 362 | `spheres/library/api/instance.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 363 | `spheres/partnership/api/policy.js` | 1 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 364 | `spheres/partnership/api/statements.js` | 0 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 365 | `spheres/partnership/api/read.js` | 1 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 366 | `spheres/partnership/api/instance.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 367 | `spheres/projects/api/policy.js` | 1 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 368 | `spheres/projects/api/instance.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 369 | `spheres/publicity/api/pipeline-fixture.js` | 0 | 2 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 370 | `spheres/publicity/api/policy.js` | 3 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 371 | `spheres/publicity/api/statements.js` | 1 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 372 | `spheres/publicity/api/stage-advance.js` | 3 | 4 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 373 | `spheres/publicity/api/instance.js` | 0 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 374 | `spheres/publicity/api/stage-pass.js` | 0 | 2 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 375 | `spheres/relationships/api/read.js` | 1 | 5 | 0 | 0 | 0 | 0 | jsonStr,groupName,tripleKey,matchSide,personJson,loadRecords |
| 376 | `spheres/relationships/api/instance.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 377 | `spheres/reputation/api/policy.js` | 1 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 378 | `spheres/reputation/api/read.js` | 1 | 2 | 0 | 0 | 0 | 0 | cleanText,listPlaces,listReviews,undismissReview |
| 379 | `spheres/reputation/api/instance.js` | 0 | 1 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 380 | `spheres/schedule/api/providers/index.js` | 3 | 3 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 381 | `spheres/schedule/api/instance.js` | 0 | 2 | 0 | 0 | 0 | 0 | reconcileDue |
| 382 | `spheres/social/api/pipeline-fixture.js` | 0 | 2 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 383 | `spheres/social/api/stage-pass.js` | 0 | 2 | 0 | 0 | 0 | 0 | (none: B not measured) |
| 384 | `agent/error-codes.js` | 2 | 0 | 0 | 0 | 0 | 0 | (none: B not measured) |

## Conventions — one name, several defining files

A name several sibling modules define is a concept with N homes, not a name to erase: the
interface of a family. A, B, C are measured over all its homes at once.

| name | homes | A | B | C | homes sample |
|---|---:|---:|---:|---:|---|
| `loadConfig` | 16 | 3 | 6 | 20 | connectors/awsconnect/sync.js, connectors/clover/sync.js, connectors/deputy/sync.js, connectors/facebook/insights-sync.js |
| `timeoutMs` | 14 | 0 | 9 | 32 | connectors/clover/api/clover-client.js, connectors/facebook/api/graph-client.js, connectors/github/api/github-client.js, connectors/googlechat/api/chat-client.js |
| `handleApi` | 13 | 12 | 42 | 373 | server/shared/contract.js, server/shared/party.js, spheres/coord/api/read.js, spheres/customer-service/api/read.js |
| `onClose` | 13 | 14 | 20 | 46 | spheres/coord/ui/views/MeetingFollowUp.tsx, spheres/customer-service/ui/views/Calls.tsx, spheres/library/ui/ItemOverlay.tsx, spheres/projects/ui/views/Gantt.tsx |
| `nowMysql` | 11 | 0 | 1 | 1 | connectors/awsconnect/api/upsert.js, connectors/clover/api/upsert.js, connectors/deputy/api/upsert.js, connectors/googlereviews/api/upsert.js |
| `runSyncPass` | 9 | 9 | 18 | 134 | connectors/awsconnect/api/sync.js, connectors/clover/api/sync.js, connectors/deputy/api/sync.js, connectors/github/api/sync.js |
| `httpRaw` | 9 | 10 | 10 | 21 | connectors/clover/api/clover-client.js, connectors/github/api/github-client.js, connectors/rezdy/api/rezdy-client.js, connectors/square/api/square-client.js |
| `defaultSleep` | 9 | 2 | 2 | 4 | connectors/awsconnect/api/aws-client.js, connectors/clover/api/clover-client.js, connectors/deputy/api/deputy-client.js, connectors/dropbox/api/dropbox-client.js |
| `INTERVAL_MIN` | 9 | 0 | 0 | 0 | connectors/awsconnect/hook.js, connectors/clover/hook.js, connectors/deputy/hook.js, connectors/github/hook.js |
| `MAX_RETRY_AFTER_MS` | 9 | 0 | 0 | 0 | connectors/clover/api/clover-client.js, connectors/deputy/api/deputy-client.js, connectors/dropbox/api/dropbox-client.js, connectors/github/api/github-client.js |
| `onOpen` | 8 | 7 | 21 | 47 | spheres/library/ui/Results.tsx, spheres/social/ui/CampaignBoard.tsx, spheres/social/ui/CampaignPipeline.tsx, spheres/social/ui/Rolodex.tsx |
| `retryAfterMs` | 8 | 0 | 2 | 9 | connectors/clover/api/clover-client.js, connectors/deputy/api/deputy-client.js, connectors/dropbox/api/dropbox-client.js, connectors/onedrive/api/graph-client.js |
| `runbook` | 7 | 0 | 53 | 221 | server/shared/anthropic.js, server/shared/deepseek.js, server/shared/model-api.js, server/shared/ollama.js |
| `tradeVocab` | 7 | 2 | 16 | 40 | spheres/social/ui/CampaignBoard.tsx, spheres/social/ui/CampaignPipeline.tsx, spheres/social/ui/CampaignWizard.tsx, spheres/social/ui/ContactDetail.tsx |
| `withRetry` | 7 | 0 | 8 | 15 | connectors/dropbox/api/dropbox-client.js, connectors/facebook/api/graph-client.js, connectors/googlechat/api/chat-client.js, connectors/googlereviews/api/serpapi-client.js |
| `entryStage` | 6 | 9 | 26 | 52 | spheres/projects/api/derive.js, web/src/pipeline/Campaigns.tsx, web/src/pipeline/ContactPanel.tsx, web/src/pipeline/Roster.tsx |
| `upsertEntity` | 6 | 6 | 20 | 103 | connectors/clover/api/upsert.js, connectors/deputy/api/upsert.js, connectors/rezdy/api/upsert.js, connectors/sonas/api/upsert.js |
| `insights-sync (stem)` | 6 | 5 | 19 | 24 | connectors/facebook/api/insights-sync.js, connectors/facebook/insights-sync.js, connectors/instagram/api/insights-sync.js, connectors/instagram/insights-sync.js |
| `ENTITY_BY_KEY` | 6 | 1 | 8 | 90 | connectors/clover/api/upsert.js, connectors/deputy/api/upsert.js, connectors/rezdy/api/upsert.js, connectors/sonas/api/upsert.js |
| `memberOf` | 6 | 0 | 2 | 3 | server/shared/spar-pipeline.js, spheres/projects/api/read.js, spheres/publicity/api/cursor.test.js, spheres/publicity/api/stage-advance.js |
| `DAY_MS` | 6 | 0 | 1 | 2 | connectors/awsconnect/api/sync.js, spheres/reputation/ui/lanes.ts, spheres/schedule/api/providers/rezdy.js, spheres/schedule/api/reconcile-logic.js |
| `finishEntity` | 6 | 0 | 1 | 1 | connectors/awsconnect/api/sync.js, connectors/clover/api/sync.js, connectors/deputy/api/sync.js, connectors/rezdy/api/sync.js |
| `touchEntity` | 6 | 0 | 1 | 1 | connectors/awsconnect/api/sync.js, connectors/clover/api/sync.js, connectors/deputy/api/sync.js, connectors/rezdy/api/sync.js |
| `loadCursors` | 6 | 0 | 1 | 1 | connectors/clover/api/sync.js, connectors/deputy/api/sync.js, connectors/googlechat/api/sync.js, connectors/rezdy/api/sync.js |
| `seedCursors` | 6 | 0 | 0 | 0 | connectors/awsconnect/api/sync.js, connectors/clover/api/sync.js, connectors/deputy/api/sync.js, connectors/rezdy/api/sync.js |
| `upsertSQL` | 6 | 0 | 0 | 0 | connectors/clover/api/upsert.js, connectors/deputy/api/upsert.js, connectors/rezdy/api/upsert.js, connectors/sonas/api/upsert.js |
| `nowMs` | 5 | 0 | 37 | 124 | connectors/deputy/api/client.test.js, connectors/github/api/client.test.js, connectors/github/api/github-client.js, connectors/rezdy/api/client.test.js |
| `campaignId` | 5 | 2 | 16 | 46 | spheres/relationships/ui/api.ts, spheres/social/api/read.js, spheres/social/ui/api.ts, spheres/social/ui/cards.tsx |
| `insertFlip` | 5 | 4 | 12 | 29 | spheres/financial/api/statements.js, spheres/partnership/api/statements.js, spheres/projects/api/statements.js, spheres/publicity/api/statements.js |
| `audienceVocab` | 5 | 2 | 11 | 29 | spheres/social/ui/CampaignWizard.tsx, spheres/social/ui/ContactDetail.tsx, spheres/social/ui/Rolodex.tsx, spheres/social/ui/cards.tsx |
| `Campaigns` | 5 | 1 | 10 | 25 | spheres/partnership/ui/sphere.tsx, spheres/partnership/ui/views/Campaigns.tsx, spheres/publicity/ui/sphere.tsx, spheres/publicity/ui/views/Campaigns.tsx |
| `isoToMysql` | 5 | 4 | 10 | 44 | connectors/googlechat/api/sync.js, connectors/googlereviews/api/upsert.js, connectors/instagram/api/jobs.js, connectors/rezdy/api/upsert.js |
| `Roster` | 5 | 1 | 8 | 19 | spheres/partnership/ui/sphere.tsx, spheres/partnership/ui/views/Roster.tsx, spheres/publicity/ui/sphere.tsx, spheres/publicity/ui/views/Roster.tsx |
| `msToMysql` | 5 | 0 | 1 | 2 | connectors/awsconnect/api/sync.js, connectors/clover/api/upsert.js, connectors/deputy/api/sync.js, connectors/xero/api/sync.js |
| `dataset` | 4 | 4 | 99 | 646 | spheres/library/ui/api.ts, web/src/app/AccessGrants.tsx, web/src/lib/auth.ts, web/src/lib/grants.ts |
| `createdAt` | 4 | 4 | 22 | 36 | spheres/coord/ui/api.ts, spheres/customer-service/ui/api.ts, spheres/projects/ui/api.ts, spheres/relationships/ui/api.ts |
| `fmtDate` | 4 | 18 | 21 | 79 | spheres/coord/ui/views/ByPerson.tsx, spheres/relationships/ui/views/PersonPanel.tsx, web/src/lib/format.ts, web/src/pipeline/api.ts |
| `People` | 4 | 0 | 14 | 25 | spheres/financial/ui/sphere.tsx, spheres/financial/ui/views/People.tsx, spheres/relationships/ui/sphere.tsx, spheres/relationships/ui/views/People.tsx |
| `toStart` | 4 | 1 | 10 | 27 | spheres/schedule/api/providers/local.js, spheres/schedule/ui/ConfirmMove.tsx, spheres/schedule/ui/api.ts, spheres/schedule/ui/views/Week.tsx |
| `authorizeUrl` | 4 | 4 | 8 | 22 | connectors/dropbox/api/dropbox-client.js, connectors/onedrive/api/graph-client.js, connectors/tiktok/api/tiktok-client.js, connectors/xero/api/xero-client.js |
| `legalName` | 4 | 0 | 7 | 30 | spheres/financial/ui/letterhead.ts, web/src/app/AccessTenants.tsx, web/src/lib/auth.ts, web/src/lib/org-identity.ts |
| `taxLabel` | 4 | 0 | 7 | 25 | spheres/financial/ui/letterhead.ts, web/src/app/AccessTenants.tsx, web/src/lib/auth.ts, web/src/lib/org-identity.ts |
| `taxId` | 4 | 0 | 7 | 24 | spheres/financial/ui/letterhead.ts, web/src/app/AccessTenants.tsx, web/src/lib/auth.ts, web/src/lib/org-identity.ts |
| `addressLine1` | 4 | 0 | 7 | 17 | spheres/financial/ui/letterhead.ts, web/src/app/AccessTenants.tsx, web/src/lib/auth.ts, web/src/lib/org-identity.ts |
| `addressLine2` | 4 | 0 | 6 | 16 | spheres/financial/ui/letterhead.ts, web/src/app/AccessTenants.tsx, web/src/lib/auth.ts, web/src/lib/org-identity.ts |
| `stagePass` | 4 | 2 | 6 | 14 | spheres/publicity/api/instance.js, spheres/publicity/api/stage-advance.js, spheres/social/api/instance.js, spheres/social/api/stage-advance.js |
| `onDone` | 4 | 3 | 4 | 16 | spheres/customer-service/ui/views/Calls.tsx, spheres/schedule/ui/EntryEditor.tsx, spheres/social/ui/CampaignWizard.tsx, web/src/lib/chat.ts |
| `exchangeCode` | 4 | 4 | 4 | 8 | connectors/dropbox/api/dropbox-client.js, connectors/onedrive/api/graph-client.js, connectors/tiktok/api/tiktok-client.js, connectors/xero/api/xero-client.js |
| `Freshness` | 4 | 1 | 1 | 4 | spheres/customer-service/ui/api.ts, spheres/relationships/ui/api.ts, web/src/pipeline/api.ts, web/src/ui/FreshnessNote.tsx |
| `onAct` | 4 | 1 | 1 | 2 | web/src/app/AccessApps.tsx, web/src/app/AccessPeople.tsx, web/src/app/AccessRoles.tsx, web/src/app/AccessWalls.tsx |
| `TOKEN_URL` | 4 | 0 | 1 | 4 | connectors/dropbox/api/dropbox-client.js, connectors/googlechat/api/chat-client.js, connectors/onedrive/api/graph-client.js, connectors/xero/api/xero-client.js |
| `DEFAULT_BASE` | 4 | 0 | 0 | 0 | connectors/clover/api/clover-client.js, connectors/github/api/github-client.js, connectors/rezdy/api/rezdy-client.js, connectors/square/api/square-client.js |
| `parseCode` | 4 | 0 | 0 | 0 | connectors/dropbox/api/consent.js, connectors/onedrive/api/consent.js, connectors/tiktok/api/auth-bootstrap.js, connectors/xero/api/auth-bootstrap.js |
| `_deps` | 4 | 0 | 0 | 0 | connectors/instagram/api/jobs.js, connectors/linkedin/api/jobs.js, connectors/otter/api/jobs.js, spheres/coord/api/jobs-a.js |
| `RUNBOOK` | 4 | 0 | 0 | 0 | scripts/stage-flip-harness.mjs, server/shared/anthropic.test.js, server/shared/deepseek.test.js, server/shared/ollama.test.js |
| `datasets` | 3 | 1 | 46 | 295 | server/shared/grants.js, web/src/app/AccessPeople.tsx, web/src/app/AccessRoles.tsx |
| `error-codes (stem)` | 3 | 16 | 29 | 55 | agent/error-codes.js, server/shared/error-codes.js, web/src/lib/error-codes.ts |
| `stage-advance (stem)` | 3 | 11 | 29 | 51 | server/shared/stage-advance.js, spheres/publicity/api/stage-advance.js, spheres/social/api/stage-advance.js |
| `basePath` | 3 | 20 | 26 | 36 | web/src/app/sphere.ts, web/src/pipeline/Campaigns.tsx, web/src/pipeline/Roster.tsx |
| `Board` | 3 | 5 | 20 | 53 | spheres/coord/ui/sphere.tsx, spheres/coord/ui/views/Board.tsx, web/src/ui/Board.tsx |
