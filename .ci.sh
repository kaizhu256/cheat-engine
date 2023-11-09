#!/bin/sh

# sh one-liner
# sh jslint_ci.sh shCiBuildWasm
# sh jslint_ci.sh shSqlmathUpdate

shCiBaseCustom() {(set -e
# this function will run custom-code for base-ci
    # .github_cache - restore
    if [ "$GITHUB_ACTION" ] && [ -d .github_cache ]
    then
        cp -a .github_cache/* . || true # js-hack - */
    fi
    #
    # init lazarus-ide
    if [ ! -d /c/lazarus/ ] && [ ! -d lazarus/ ]
    then
        git clone \
            --branch=v2.2.2 \
            --depth=1 \
            --single-branch \
            https://github.com/kaizhu256/lazarus-win32 lazarus
    fi
    if [ ! -d /c/lazarus/ ]
    then
        mv lazarus /c/
    fi
    export PATH="$PATH:/c/lazarus/:/c/lazarus/fpc/3.2.2/bin/x86_64-win64/"
    # .github_cache - save
    if [ "$GITHUB_ACTION" ] && [ ! -d .github_cache/lazarus/ ]
    then
        mkdir -p .github_cache
        cp -a /c/lazarus .github_cache/
    fi
    #
    # build cheat-engine
    (
    cd "Cheat Engine/"
    # lazbuild cheatengine.lpi --build-mode="Release 64-Bit O4 AVX2"
    # find . | grep "\.ppu$\|\.ppl$\|\.o$\|\.or$" | xargs rm
    # find . | grep "\.lpi" | grep -v "\/backup\/"
    PID_LIST=""
    for FILE in \
        "Tutorial/tutorial.lpi" \
        "VEHDebug/vehdebug.lpi" \
        "_Tutorial/graphical/project1.lpi" \
        "_cecore.lpi" \
        "cepack/cepack.lpi" \
        "_ceregreset/ceregreset.lpi" \
        "dbk32/Kernelmodule unloader/Kernelmoduleunloader.lpi" \
        "_launcher/cheatengine.lpi" \
        "_luaclient/testapp/luaclienttest.lpi" \
        "_plugin/DebugEventLog/src/DebugEventLog.lpi" \
        "_plugin/example/exampleplugin.lpi" \
        "_sfx/level2/standalonephase2.lpi" \
        "_speedhack/speedhacktest/speedhacktest.lpi" \
        "_windowsrepair/windowsrepair.lpi" \
        "_xmplayer/xmplayer.lpi" \
        "allochook/allochook.lpi" \
        "_cheatengine.lpi" \
        "debuggertest/debuggertest.lpi" \
        "luaclient/luaclient.lpi" \
        "plugin/forcedinjection/forcedinjection.lpi" \
        "speedhack/speedhack.lpi" \
        "winhook/winhook.lpi" \
        "__sentinel__"
    do
        node --input-type=module --eval '
import moduleAssert from "assert";
import moduleChildProcess from "child_process";
import moduleFs from "fs";
(async function () {
    let data;
    let file = process.argv[1];
    if (file.startsWith("_")) {
        return;
    }
    data = await moduleFs.promises.readFile(file, "utf8");
    data = (/<BuildModes\b[\S\s]*?<\/BuildModes>/).exec(data)[0];
    data = data.matchAll(/Name=(".*?")/g);
    data = Array.from(data).map(function (elem) {
        return elem[1];
    });
    data = data.sort(function (aa, bb) {
        let cmp;
        aa = aa.toLowerCase();
        bb = bb.toLowerCase();
        [aa, bb].forEach(function (cc, ii) {
            if (cmp) {
                return;
            }
            ii -= 0.5;
            if (cc.includes("debug")) {
                cmp = -ii;
                return;
            }
            if (cc.includes("32")) {
                cmp = -ii;
                return;
            }
            if (cc.includes("64")) {
                cmp = ii;
                return;
            }
            if (cc.includes("release")) {
                cmp = ii;
                return;
            }
        });
        return cmp;
    })[0];
    data = `lazbuild "${file}" --build-mode="${data}"`;
    console.error(`\n\n\n\n${data}`);
    moduleChildProcess.spawn(
        "bash",
        ["-c", data],
        {stdio: ["ignore", 1, 2]}
    ).on("exit", function (exitCode) {
        moduleAssert.ok(exitCode === 0, `exitCode=${exitCode}`);
    });
}());
' "$FILE" # '
        # !! printf "$BUILD_COMMAND\n"
            # !! node --eval
            # !! BUILD_MODE0="$(cat cheatengine.lpi \
                # !! | grep -Pzo "\<BuildModes.*\>\n(.*?\n){1,} *<\/BuildModes\>\n")"
            # !! BUILD_MODE=""
            # !! if [ ! "$BUILD_MODE" ]
            # !! then
                # !! BUILD_MODE="$(
                    # !! cat "$FILE" \
                        # !! | grep -i -v "debug" \
                        # !! | grep -i -m1 -o 'item. name="[^"]*64[^"]*"' \
                        # !! | grep -o '"[^"]*"' | grep -o '[^"]*'
                # !! )" || true
            # !! fi
            # !! if [ ! "$BUILD_MODE" ]
            # !! then
                # !! BUILD_MODE="$(
                    # !! cat "$FILE" \
                        # !! | grep -i -v "32" \
                        # !! | grep -i -m1 -o 'item. name="[^"]*"' \
                        # !! | grep -o '"[^"]*"' | grep -o '[^"]*'
                # !! )" || true
            # !! fi
            # !! if [ ! "$BUILD_MODE" ]
            # !! then
                # !! BUILD_MODE="$(
                    # !! cat "$FILE" \
                        # !! | grep -i -m1 -o 'item. name="[^"]*"' \
                        # !! | grep -o '"[^"]*"' | grep -o '[^"]*'
                # !! )" || true
            # !! fi
            # !! BUILD_COMMAND="lazbuild \"$FILE\" --bm=\"$BUILD_MODE\""
            # !! printf "\n\n\n\n$BUILD_COMMAND\n"
            # !! if [ ! "$BUILD_MODE" ]
            # !! then
                # !! exit 1
            # !! fi
            # !! # !! eval "$BUILD_COMMAND"
            # !! # !! PID_LIST="$PID_LIST $!"
            # !! ;;
        # !! esac
    done
    # !! shPidListWait build_ext "$PID_LIST"
    printf "0\n"
    )
    #
    # upload artifact
    if (shCiMatrixIsmainNodeversion) && ( \
        [ "$GITHUB_BRANCH0" = alpha ] \
        || [ "$GITHUB_BRANCH0" = beta ] \
        || [ "$GITHUB_BRANCH0" = master ] \
    )
    then
        export GITHUB_UPLOAD_RETRY=0
        while true
        do
            GITHUB_UPLOAD_RETRY="$((GITHUB_UPLOAD_RETRY + 1))"
            if [ "$GITHUB_UPLOAD_RETRY" -gt 4 ]
            then
                return 1
            fi
            if (node --input-type=module --eval '
import moduleChildProcess from "child_process";
(function () {
    moduleChildProcess.spawn(
        "sh",
        ["jslint_ci.sh", "shCiBaseCustomArtifactUpload"],
        {stdio: ["ignore", 1, 2]}
    ).on("exit", process.exit);
}());
' "$@") # '
            then
                break
            fi
        done
    fi
)}

shCiBaseCustomArtifactUpload() {(set -e
# this function will upload build-artifacts to branch-gh-pages
    COMMIT_MESSAGE="- upload artifact
- retry$GITHUB_UPLOAD_RETRY
- $GITHUB_BRANCH0
- $(printf "$GITHUB_SHA" | cut -c-8)
- $(uname)
"
    printf "\n\n$COMMIT_MESSAGE\n"
    # init .git/config
    git config --local user.email "github-actions@users.noreply.github.com"
    git config --local user.name "github-actions"
    # git clone origin/artifact
    rm -rf .tmp/artifact
    shGitCmdWithGithubToken clone origin .tmp/artifact \
        --branch=artifact --single-branch
    (
    cd .tmp/artifact/
    cp ../../.git/config .git/config
    # update dir branch-$GITHUB_BRANCH0
    mkdir -p "branch-$GITHUB_BRANCH0/"
    case "$(uname)" in
    Darwin*)
        ;;
    Linux*)
        ;;
    MINGW64_NT*)
        rm -f "branch-$GITHUB_BRANCH0/"*.dll
        rm -f "branch-$GITHUB_BRANCH0/"*.exe
        ;;
    esac
    cp "../../Cheat Engine/bin/"*.dll "branch-$GITHUB_BRANCH0/"
    cp "../../Cheat Engine/bin/"*.exe "branch-$GITHUB_BRANCH0/"
    # git commit
    git add .
    if (git commit -am "$COMMIT_MESSAGE")
    then
        # git push
        shGitCmdWithGithubToken push origin artifact
        # git squash
        if [ "$GITHUB_BRANCH0" = alpha ]
        then
            shGitCommitPushOrSquash "" 50
        fi
    fi
    # debug
    shGitLsTree
    )
)}
