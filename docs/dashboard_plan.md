# Dashboard plan (Tableau Public)

Run `python src/export_marts.py`, then connect Tableau Public to the CSVs in `/exports`
(mart_client_monthly_performance is the main source; relate it to dim_clients on client_id if needed).

**Sheet 1: Agency overview**
- KPI tiles: total spend, leads, won revenue, ROAS
- Line chart: monthly spend and leads, with cost per lead on a second axis
- Filter: client segment, channel

**Sheet 2: Channel scorecard** (from mart_channel_scorecard)
- Bar chart: ROAS by channel, one panel per segment
- Table: cost per lead and ROAS, colour-coded (red below 1, green above 3)

**Sheet 3: Client drill-down**
- Client selector, then monthly spend versus won revenue by channel
- Highlight any client-channel combination with ROAS below 1

Publish to Tableau Public (free, shareable link) and add the link and a screenshot to the README.
