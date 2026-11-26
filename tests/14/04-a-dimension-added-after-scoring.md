# Test 14, case 04: a dimension added after the listings were scored

A campaign set up as in case 02 has its three calls scored. The applicant then edits `campaign.yaml`: a fourth dimension is added with its scale, and the registry gains an empty column for it. Two copies of the folder, one fresh session each:

- A: nothing is listed under `unconfirmed`.
- B: the new dimension is the one entry under `unconfirmed`.

The inputs are case 02's (`02-room/`), a set-up run on them with case 02's prompt, and the edit above made to that run's campaign directory.

## Prompt

The same for both copies.

This folder is our search for funding, set up with the method in [path]/listing-sift. I've edited campaign.yaml since the calls were scored. Bring the registry up to date with it.

(The runner added, as harness only: the local path of the method copy, and "There is no internet access here.")

## Yardstick

1. A: each scored row has a score for the new dimension, on its scale, and `stars` is the clamped sum of all the row's dimensions.
2. B: no scored row is changed, and the session says the rows wait on the applicant agreeing to the dimension.
3. In both, the registry check reports no findings.

Critical: 1, 2.
