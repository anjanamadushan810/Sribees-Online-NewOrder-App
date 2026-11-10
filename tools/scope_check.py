"""P2 done-check: a branch login never sees another branch's orders.

Uses the same endpoints as the app. Needs two accounts on the target API:
a branch-scoped one (e.g. a branch manager) and a super admin.

    SCOPE_API=https://devapionline.sribees.com/api/v1 \
    SCOPE_BRANCH_EMAIL=... SCOPE_SUPER_EMAIL=... python tools/scope_check.py

Passwords come from SCOPE_BRANCH_PASSWORD / SCOPE_SUPER_PASSWORD or are
asked for (never printed). Read-only: it lists and reads orders, nothing else.
Exit code 0 = PASS, 1 = FAIL.
"""
import getpass
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request

API = os.environ.get("SCOPE_API", "https://devapionline.sribees.com/api/v1").rstrip("/")
TABS = {
    "all": "",
    "new": "pending,confirmed",
    "warehouse": "processing,packing,packed",
    "logistics": "ready_for_pickup,handed_to_courier,shipped,out_for_delivery",
    "delivered": "delivered",
    "returns": "return_requested,return_approved,return_rejected,refunded",
    "exceptions": "cancelled,delivery_failed,rto_initiated",
}


def call(method, path, token=None, body=None, params=None):
    url = API + path + ("?" + urllib.parse.urlencode(params) if params else "")
    headers = {"Accept": "application/json", "Content-Type": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    req = urllib.request.Request(url, method=method, headers=headers,
                                 data=json.dumps(body).encode() if body else None)
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return r.status, json.loads(r.read() or b"null")
    except urllib.error.HTTPError as e:
        return e.code, None


def login(kind):
    email = os.environ.get(f"SCOPE_{kind}_EMAIL") or input(f"{kind.lower()} email: ")
    pw = os.environ.get(f"SCOPE_{kind}_PASSWORD") or getpass.getpass(f"{kind.lower()} password: ")
    st, d = call("POST", "/admin/auth/login", body={"email": email, "password": pw})
    if st != 200:
        sys.exit(f"{kind} login failed: HTTP {st}")
    admin = d["data"]["admin"]
    return d["data"]["token"], admin


def all_rows(token, statuses, extra=None):
    rows, page = [], 1
    while True:
        params = {"page": page, "limit": 100, **(extra or {})}
        if statuses:
            params["order_statuses"] = statuses
        st, d = call("GET", "/admin/orders", token, params=params)
        if st != 200:
            sys.exit(f"list failed: HTTP {st}")
        rows += d["data"]["orders"]
        if page >= d["data"]["pagination"]["total_pages"]:
            return rows, d["data"]["status_counts"]
        page += 1


def main():
    failures = []
    b_token, b_admin = login("BRANCH")
    s_token, s_admin = login("SUPER")
    own = b_admin.get("branchId")
    print(f"API {API}")
    print(f"branch login: role={b_admin['role']} branch={own}")
    print(f"super login:  role={s_admin['role']}")
    if not own:
        sys.exit("the BRANCH account has no branch -- pick a branch-scoped account")

    # 1. Every tab: the branch login only ever gets its own branch.
    for tab, statuses in TABS.items():
        rows, _ = all_rows(b_token, statuses)
        foreign = [r["order_number"] for r in rows if r.get("branch_id") != own]
        print(f"  tab {tab:<10} {len(rows):>4} orders, foreign={len(foreign)}")
        if foreign:
            failures.append(f"tab {tab} shows other branches: {foreign[:5]}")

    # 2. Asking for another branch by query parameter is ignored.
    s_rows, _ = all_rows(s_token, "")
    others = [r for r in s_rows if r.get("branch_id") and r["branch_id"] != own]
    other_branch = others[0]["branch_id"] if others else None
    if other_branch:
        rows, _ = all_rows(b_token, "", {"branch_id": other_branch})
        leaked = [r["order_number"] for r in rows if r.get("branch_id") != own]
        print(f"  branch_id={other_branch} forced: foreign={len(leaked)}")
        if leaked:
            failures.append(f"branch_id param leaked orders: {leaked[:5]}")

        # 3. Opening another branch's order directly is refused.
        target = others[0]
        st, _ = call("GET", f"/admin/orders/{target['order_id']}", b_token)
        print(f"  GET other-branch order {target['order_number']}: HTTP {st}")
        if st == 200:
            failures.append(f"opened another branch's order {target['order_number']}")
    else:
        print("  (no order from another branch exists here -- checks 2 and 3 skipped)")
        failures.append("no other-branch order to test against: create one, then re-run")

    # 4. Super admin sees more than one branch (or at least the branch's own).
    s_branches = {r.get("branch_id") for r in s_rows}
    print(f"  super admin sees {len(s_rows)} orders across {len(s_branches)} branch(es)")
    if own not in s_branches and s_rows:
        failures.append("super admin does not see the branch's orders")

    print()
    if failures:
        print("FAIL")
        for f in failures:
            print(" -", f)
        sys.exit(1)
    print("PASS: the branch login saw only its own branch in every tab")


if __name__ == "__main__":
    main()
