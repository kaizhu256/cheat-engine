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
    for FILE in $(find . | grep "\.lpi" | grep -v "\/backup\/")
    do
        printf "\n\nlazbuild $FILE ...\n"
        BUILD_MODE="$(
            cat "$FILE" \
                | grep -i -v "debug" \
                | grep -i -m1 -o 'item. name="[^"]*64[^"]*"' \
                | grep -o '"[^"]*"' | grep -o '[^"]*' 2>/dev/null
        )" || true
        if [ "$BUILD_MODE" ]
        then
            printf "lazbuild $FILE --bm=\"$BUILD_MODE\"\n"
            lazbuild "$FILE" --bm="$BUILD_MODE"
        fi
    done
    # lazbuild --bm="Release 64-Bit" allochook/allochook.lpi
    # lazbuild --bm="Release 64-Bit" backup/cheatengine.lpi
    # lazbuild --bm="Release 64-Bit" cecore.lpi
    # lazbuild --bm="Release 64-Bit" cepack/cepack.lpi
    # lazbuild --bm="Release 64-Bit" ceregreset/ceregreset.lpi
    lazbuild --bm="Release 64-Bit" cheatengine.lpi
    # lazbuild --bm="Release 64-Bit" \
    #     "dbk32/Kernelmodule unloader/Kernelmodule unloader.lpi"
    lazbuild --bm="Release 64-Bit" debuggertest/debuggertest.lpi
    # lazbuild --bm="Release 64-Bit" launcher/cheatengine.lpi
    # lazbuild --bm="Release 64-Bit" luaclient/backup/luaclient.lpi
    lazbuild --bm="Release 64-Bit" luaclient/luaclient.lpi
    lazbuild --bm="Release 64-Bit" luaclient/testapp/luaclienttest.lpi
    # lazbuild --bm="Release 64-Bit" plugin/DebugEventLog/src/DebugEventLog.lpi
    lazbuild --bm="Release 64-Bit" plugin/example/exampleplugin.lpi
    # lazbuild --bm="Release 64-Bit" plugin/forcedinjection/forcedinjection.lpi
    # lazbuild --bm="Release 64-Bit" sfx/level2/standalonephase2.lpi
    # lazbuild --bm="Release 64-Bit" speedhack/backup/speedhack.lpi
    lazbuild --bm="Release 64-Bit" speedhack/speedhack.lpi
    # lazbuild --bm="Release 64-Bit" speedhack/speedhacktest/speedhacktest.lpi
    # lazbuild --bm="Release 64-Bit" Tutorial/backup/tutorial.lpi.bak
    lazbuild --bm="Release 64-Bit" Tutorial/graphical/project1.lpi
    lazbuild --bm="Release 64-Bit" Tutorial/tutorial.lpi
    # lazbuild --bm="Release 64-Bit" VEHDebug/backup/vehdebug.lpi
    lazbuild --bm="Release 64-Bit" VEHDebug/vehdebug.lpi
    # lazbuild --bm="Release 64-Bit" windowsrepair/windowsrepair.lpi
    # lazbuild --bm="Release 64-Bit" winhook/winhook.lpi
    # lazbuild --bm="Release 64-Bit" xmplayer/xmplayer.lpi
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
    cp ../../bin/*.dll "branch-$GITHUB_BRANCH0/"
    cp ../../bin/*.exe "branch-$GITHUB_BRANCH0/"
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
