"""Generate SYNTHETIC raw data for a fictional multi-client marketing agency.

Everything here is simulated: the clients are fictional, and the channel
benchmarks (CTR, CPC, conversion rates, deal sizes) are illustrative
assumptions, not real market figures.

The raw tables are written to /seeds so `dbt seed` can load them. In a real
agency these would come from ad-platform exports or APIs and a CRM.

The data is deliberately imperfect (inconsistent channel labels, messy lead
stages, duplicate rows, clicks above impressions) so the dbt staging layer
has real cleaning to do.
"""
from pathlib import Path

import numpy as np
import pandas as pd

SEED = 7
START, END = pd.Timestamp("2025-10-01"), pd.Timestamp("2026-08-31")
OUT = Path(__file__).resolve().parents[1] / "seeds"

# client_name, segment, province, onboarded, monthly retainer (ZAR), average deal size (ZAR)
CLIENTS = [
    ("Apex Build Group", "Developer", "Gauteng", "2025-06-01", 18000, 900_000),
    ("Ridgeview Developments", "Developer", "Gauteng", "2025-07-15", 15000, 750_000),
    ("Stonecrest Construction", "Contractor", "Gauteng", "2025-05-01", 12000, 260_000),
    ("Blueline Civils", "Contractor", "Western Cape", "2025-08-01", 12000, 230_000),
    ("Ironwood Building Supplies", "Supplier", "Gauteng", "2025-09-01", 9000, 46_000),
    ("Highveld Materials", "Supplier", "Mpumalanga", "2025-09-15", 9000, 40_000),
    ("Savanna Estates", "Estate Agency", "Gauteng", "2025-07-01", 10000, 42_000),
    ("Urban Nest Properties", "Estate Agency", "KwaZulu-Natal", "2025-08-15", 10000, 38_000),
]

# channel: (dirty labels, CTR, avg CPC ZAR, click-to-lead rate, lead quality multiplier)
# Quality multiplier scales the chance a lead becomes a won deal: cheap Meta leads
# are lower quality, LinkedIn leads cost more but convert better.
CHANNELS = {
    "Google Ads": (["Google Ads", "google ads", "Google"], 0.050, 22.0, 0.030, 1.2),
    "Meta Ads": (["Meta Ads", "Facebook", "Facebook/Instagram"], 0.012, 8.0, 0.020, 0.7),
    "LinkedIn Ads": (["LinkedIn Ads", "LinkedIn", "linkedin ads"], 0.006, 55.0, 0.025, 2.0),
    "Property Portal": (["Property Portal", "Portal"], 0.020, 14.0, 0.035, 1.0),
}
# Base lead-to-won rate by client segment (illustrative)
WIN_RATE = {"Developer": 0.008, "Contractor": 0.025, "Supplier": 0.05, "Estate Agency": 0.04}
STAGE_DIRTY = {"New": ["New", "new", "NEW "], "Qualified": ["Qualified", "qualified"],
               "Proposal": ["Proposal", "proposal "], "Won": ["Won", "won", "WON", "Won "],
               "Lost": ["Lost", "lost", "LOST"]}


def main() -> None:
    rng = np.random.default_rng(SEED)
    OUT.mkdir(exist_ok=True)

    clients = pd.DataFrame(CLIENTS, columns=["client_name", "segment", "province", "onboarded_date",
                                              "monthly_retainer_zar", "avg_deal_zar"])
    clients.insert(0, "client_id", [f"C{i + 1:03d}" for i in range(len(clients))])
    deal_size = dict(zip(clients["client_id"], clients["avg_deal_zar"]))
    segment_of = dict(zip(clients["client_id"], clients["segment"]))

    # ---- campaigns ---------------------------------------------------------
    camp_rows = []
    n = 0
    for cid in clients["client_id"]:
        for _ in range(rng.integers(3, 7)):
            n += 1
            channel = rng.choice(list(CHANNELS), p=[0.35, 0.30, 0.15, 0.20])
            objective = rng.choice(["Lead Gen", "Brand Awareness"], p=[0.8, 0.2])
            start = START + pd.Timedelta(days=int(rng.integers(0, 200)))
            end = min(start + pd.Timedelta(days=int(rng.integers(60, 220))), END)
            camp_rows.append({
                "campaign_id": f"CMP{n:04d}", "client_id": cid,
                "channel": rng.choice(CHANNELS[channel][0]),
                "true_channel": channel, "objective": objective,
                "campaign_name": f"{channel.split()[0]} {objective} {n:02d}",
                "start_date": start.date(), "end_date": end.date(),
            })
    camps = pd.DataFrame(camp_rows)

    # ---- daily ad performance + leads ---------------------------------------
    perf_rows, lead_rows = [], []
    lead_no = 0
    for c in camps.itertuples():
        _, ctr, cpc, conv, quality = CHANNELS[c.true_channel]
        if c.objective == "Brand Awareness":
            ctr, conv = ctr * 0.8, conv * 0.15
        budget = rng.uniform(700, 3300)                     # daily budget in ZAR
        p_won = WIN_RATE[segment_of[c.client_id]] * quality * rng.lognormal(0, 0.3)
        # each campaign has its own efficiency, so campaigns genuinely differ
        efficiency = rng.lognormal(0, 0.25)
        for day in pd.date_range(c.start_date, c.end_date):
            weekday_factor = 0.75 if day.weekday() >= 5 else 1.0
            spend = budget * weekday_factor * rng.uniform(0.85, 1.1)
            clicks = rng.poisson(spend / (cpc / efficiency))
            impressions = int(clicks / max(ctr * rng.uniform(0.8, 1.2), 0.001))
            perf_rows.append((c.campaign_id, day.date(), impressions, int(clicks), round(spend, 2)))

            for _ in range(rng.binomial(clicks, min(conv * efficiency, 0.5))):
                lead_no += 1
                u = rng.random()
                stage = "Won" if u < p_won else "Proposal" if u < p_won + 0.06 else \
                        "Qualified" if u < p_won + 0.28 else "Lost" if u < p_won + 0.63 else "New"
                if day + pd.Timedelta(days=60) > END and stage in ("Won", "Lost"):
                    stage = "Qualified"                       # recent leads aren't closed yet
                value, closed = np.nan, pd.NaT
                if stage == "Won":
                    value = round(rng.lognormal(np.log(deal_size[c.client_id]), 0.35), -2)
                    closed = day + pd.Timedelta(days=int(rng.integers(14, 60)))
                elif stage == "Lost":
                    closed = day + pd.Timedelta(days=int(rng.integers(7, 45)))
                lead_rows.append((f"LD{lead_no:06d}", c.campaign_id, day.date(),
                                  rng.choice(STAGE_DIRTY[stage]), value,
                                  closed.date() if pd.notna(closed) else None))

    perf = pd.DataFrame(perf_rows, columns=["campaign_id", "report_date", "impressions", "clicks", "spend_zar"])
    leads = pd.DataFrame(lead_rows, columns=["lead_id", "campaign_id", "created_date", "stage",
                                             "deal_value_zar", "closed_date"])

    # ---- inject data errors --------------------------------------------------
    bad = perf.sample(frac=0.006, random_state=SEED).index
    perf.loc[bad, "clicks"] = perf.loc[bad, "impressions"] + rng.integers(5, 50, len(bad))   # clicks > impressions
    dupes = perf.sample(frac=0.01, random_state=SEED + 1)
    perf = pd.concat([perf, dupes], ignore_index=True).sample(frac=1, random_state=SEED).reset_index(drop=True)

    clients.drop(columns="avg_deal_zar").to_csv(OUT / "raw_clients.csv", index=False)
    camps.drop(columns="true_channel").to_csv(OUT / "raw_campaigns.csv", index=False)
    perf.to_csv(OUT / "raw_ad_performance.csv", index=False)
    leads.to_csv(OUT / "raw_leads.csv", index=False)
    print(f"clients={len(clients)}  campaigns={len(camps)}  ad_performance rows={len(perf):,}  leads={len(leads):,}")


if __name__ == "__main__":
    main()
