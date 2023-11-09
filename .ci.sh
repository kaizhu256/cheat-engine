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
        "_cepack/cepack.lpi" \
        "_ceregreset/ceregreset.lpi" \
        "_dbk32/Kernelmodule unloader/Kernelmoduleunloader.lpi" \
        "_launcher/cheatengine.lpi" \
        "_luaclient/testapp/luaclienttest.lpi" \
        "_plugin/DebugEventLog/src/DebugEventLog.lpi" \
        "_plugin/example/exampleplugin.lpi" \
        "_sfx/level2/standalonephase2.lpi" \
        "_speedhack/speedhacktest/speedhacktest.lpi" \
        "_windowsrepair/windowsrepair.lpi" \
        "_xmplayer/xmplayer.lpi" \
        "allochook/allochook.lpi" \
        "cheatengine.lpi" \
        "debuggertest/debuggertest.lpi" \
        "luaclient/luaclient.lpi" \
        "plugin/forcedinjection/forcedinjection.lpi" \
        "speedhack/speedhack.lpi" \
        "winhook/winhook.lpi" \
        "__sentinel__"
    do
        case $FILE in
        _*)
            ;;
        *)
            BUILD_MODE="$(
                cat "$FILE" \
                    | grep -i -v "debug" \
                    | grep -i -m1 -o 'item. name="[^"]*64[^"]*"' \
                    | grep -o '"[^"]*"' | grep -o '[^"]*'
            )" || true
            if [ "$BUILD_MODE" ]
            then
                printf "\n\n\n\nlazbuild $FILE --bm=\"$BUILD_MODE\"\n"
                lazbuild "$FILE" --bm="$BUILD_MODE"
            else
                printf "lazbuild $FILE\n"
                lazbuild "$FILE"
            fi
            # !! PID_LIST="$PID_LIST $!"
            ;;
        esac
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
