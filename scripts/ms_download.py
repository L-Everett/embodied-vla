#!/usr/bin/env python3
"""从魔搭 (ModelScope) 下载 模型/数据集 仓库的全部文件到本地目录（仅标准库）。

用法:
  python scripts/ms_download.py <repo_id> <models|datasets> <local_dir> [revision]
例:
  python scripts/ms_download.py lerobot/smolvla_base models /root/autodl-tmp/models/smolvla_base
  python scripts/ms_download.py lerobot/libero datasets /root/autodl-tmp/datasets/libero
"""
import concurrent.futures
import json
import os
import sys
import urllib.request

UA = {"User-Agent": "Mozilla/5.0"}
BASE = "https://modelscope.cn"


def _get_json(url):
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def list_files(repo, kind, revision):
    for ep in ("tree", "files"):
        paths = []
        page = 1
        while True:
            url = (
                f"{BASE}/api/v1/{kind}/{repo}/repo/{ep}"
                f"?Revision={revision}&Recursive=true&PageNumber={page}&PageSize=1000"
            )
            try:
                data = _get_json(url)
            except Exception:
                break
            dd = data.get("Data") or {}
            files = dd.get("Files") or []
            paths += [f["Path"] for f in files if f.get("Type") == "blob"]
            total = dd.get("TotalCount") or data.get("TotalCount") or 0
            if len(files) < 1000 or (total and len(paths) >= total):
                break
            page += 1
        if paths:
            return paths
    raise RuntimeError(f"无法获取文件列表: {kind}/{repo}")


def download(repo, kind, revision, path, local_dir):
    dest = os.path.join(local_dir, path)
    if os.path.exists(dest) and os.path.getsize(dest) > 0:
        return "skip"
    os.makedirs(os.path.dirname(dest) or ".", exist_ok=True)
    url = f"{BASE}/{kind}/{repo}/resolve/{revision}/{path}"
    tmp = dest + ".part"
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=300) as r, open(tmp, "wb") as f:
        while True:
            chunk = r.read(1 << 20)
            if not chunk:
                break
            f.write(chunk)
    os.replace(tmp, dest)
    return "ok"


def main():
    repo, kind, local_dir = sys.argv[1], sys.argv[2], sys.argv[3]
    revision = sys.argv[4] if len(sys.argv) > 4 else "master"
    os.makedirs(local_dir, exist_ok=True)
    files = list_files(repo, kind, revision)
    print(f"[ms] {kind}/{repo}: {len(files)} files -> {local_dir}", flush=True)
    ok = skip = fail = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
        futs = {ex.submit(download, repo, kind, revision, p, local_dir): p for p in files}
        for i, fu in enumerate(concurrent.futures.as_completed(futs), 1):
            try:
                st = fu.result()
                ok += st == "ok"
                skip += st == "skip"
            except Exception as e:  # noqa: BLE001
                fail += 1
                print("  FAIL", futs[fu], repr(e), flush=True)
            if i % 10 == 0 or i == len(files):
                print(f"  {i}/{len(files)}  ok={ok} skip={skip} fail={fail}", flush=True)
    print(f"[ms] done {kind}/{repo}: ok={ok} skip={skip} fail={fail}", flush=True)
    sys.exit(1 if fail else 0)


if __name__ == "__main__":
    main()
