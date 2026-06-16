import { Config, FileData } from "./types.ts";
import { Peer } from "./Peer.ts";
import { PeerStorage } from "./PeerStorage.ts";
import { PeerCouchDB } from "./PeerCouchDB.ts";

// ─────────────────────────────────────────────────────────────────────────────
// PAB Phase 2-1 단방향 패치 (방법 A 외부연계)
//
// livesync-bridge 는 네이티브 one-way 옵션이 없다. 원본 Hub.dispatch 는 같은 group 의
// 모든 peer 에 put/delete 를 전파하므로, storage(미러)가 변경되면 couchdb 로 역전파한다.
// 그러면 (1) CouchDB 읽기전용 계정/validate_doc_update 에 의해 forbidden 이 발생하고,
// (2) 그 forbidden 이 uncaught LiveSyncError 로 컨테이너를 크래시시킨다.
//
// 본 패치는 dispatch 단계에서 "storage -> couchdb" 방향을 원천 차단하여
// 엄격한 단방향(CouchDB -> 파일)만 허용한다. (CouchDB 측 권한 차단은 그대로 2차 방어선)
//
// 차단 규칙: source 가 storage 타입이고 target 이 couchdb 타입이면 전파하지 않는다.
// (couchdb -> storage, couchdb -> couchdb, storage -> storage 는 그대로 동작)
// ─────────────────────────────────────────────────────────────────────────────

export class Hub {
    conf: Config;
    peers = [] as Peer[];
    constructor(conf: Config) {
        this.conf = conf;
    }
    start() {
        for (const p of this.peers) {
            p.stop();
        }
        this.peers = [];
        for (const peer of this.conf.peers) {
            if (peer.type == "couchdb") {
                const p = new PeerCouchDB(peer, this.dispatch.bind(this));
                this.peers.push(p);
            } else if (peer.type == "storage") {
                const p = new PeerStorage(peer, this.dispatch.bind(this));
                this.peers.push(p);
            } else {
                throw new Error(`Unexpected Peer type: ${(peer as any)?.name} - ${(peer as any)?.type}`);
            }
        }
        for (const p of this.peers) {
            p.start();
        }
    }

    async dispatch(source: Peer, path: string, data: FileData | false) {
        for (const peer of this.peers) {
            if (peer !== source && (source.config.group ?? "") === (peer.config.group ?? "")) {
                // [PAB 단방향 패치] storage -> couchdb 역방향 전파 차단
                if (source.config.type === "storage" && peer.config.type === "couchdb") {
                    // 미러(파일) 변경을 CouchDB 로 되돌려쓰지 않는다. (R-1: 원본 권위는 LiveSync)
                    continue;
                }
                let ret = false;
                if (data === false) {
                    ret = await peer.delete(path);
                } else {
                    ret = await peer.put(path, data);
                }
                if (ret) {
                    // Logger(`  ${data === false ? "-x->" : "--->"} ${peer.config.name} ${path} `)
                } else {
                    // Logger(`        ${peer.config.name} ignored ${path} `)
                }
            }
        }
    }
}
