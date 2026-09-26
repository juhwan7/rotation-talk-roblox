import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const sha = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim();
const place = fs.readFileSync(path.join(root, 'build/RotationTalk.rbxlx'));
const digest = createHash('sha256').update(place).digest('hex');
const info = `Rotation Talk — Studio 개발용 장소 파일

원본 커밋: ${sha}
생성 시각(UTC): ${new Date().toISOString()}
SHA-256: ${digest}

1. Assets(첨부 파일)에서 RotationTalk.rbxlx를 다운로드합니다.
2. Roblox Studio의 File → Open from File에서 파일을 엽니다.
3. Play를 누르면 강당과 대화 테이블이 생성됩니다.

이 파일은 자동 코드 검사를 통과한 개발 빌드입니다.
실제 Studio 플레이·다중 접속·저장 부하 검증과 Roblox 게시를 대신하지 않습니다.
GitHub 업데이트는 현재 열린 Studio나 Roblox 게임에 자동 반영되지 않습니다.
Studio에서 직접 편집한 내용은 새 파일을 열기 전에 별도 파일로 보관하세요.
`;
fs.writeFileSync(path.join(root, 'build/BUILD-INFO.txt'), info);
fs.writeFileSync(path.join(root, 'build/SHA256SUMS.txt'), `${digest}  RotationTalk.rbxlx\n`);
console.log(`Release metadata created for ${sha}`);
