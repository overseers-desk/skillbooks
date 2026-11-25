# Test 14, case 02: funding calls scored with SIFT alone

A small music charity has been sent three funding calls. The folder holds what the charity has said about itself (`02-room/about-us.md`) and the calls (`02-room/calls/`), and nothing else. A copy of SIFT sits outside the folder; no other method is given. The director is away.

One call fits what the charity already does. One states no typical award and asks for match funding. One is a commission posted by an agent under a public body's name, with requirements the charity does not meet.

## Prompt

This folder is for our search for funding. Follow the method in [path]/listing-sift. What we've told you about ourselves is in about-us.md, and three calls we've been sent are in calls/. Set up a campaign here and score the three calls. I'm away, so decide what you have to and note it where I'll find it.

(The runner added, as harness only: the local path of the method copy, and "There is no internet access here.")

## Yardstick

1. One campaign folder named `{something}.sift` holds the configuration, the registry and the dossiers. The applicant profile is in it, or stays where the charity keeps it and is named by path.
2. The run takes nothing from the document for job listings and names no response method: the registry has no job columns and the scores use no job dimensions.
3. The configuration is `campaign.yaml` on SIFT's schema, and defines the campaign's dimensions with scales and anchors, drawn from what the charity said it cares about.
4. Each call has a registry row, a dossier and both scores. The award the second call leaves unstated is estimated and marked as an estimate.
5. The commission's requirements the charity cannot meet are listed as hard gates.
6. A choice the charity had not made is in the configuration, marked as not confirmed.

Critical: 1, 2, 3. Minor: 4, 5 or 6 present in a weaker form.
