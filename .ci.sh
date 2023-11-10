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
    for FILE in $(find . | grep "\.lpi" | grep -v "\/backup\/" | sort)
    do
        if [ "$FILE" = "./dbk32/Kernelmodule" ]
        then
            FILE="./dbk32/Kernelmodule unloader/Kernelmoduleunloader.lpi"
        fi
        case $FILE in
        # "./dbk32/Kernelmodule unloader/Kernelmoduleunloader.lpi") ;;
        # ./Tutorial/graphical/project1.lpi) ;;
        # ./Tutorial/tutorial.lpi) ;;
        # ./VEHDebug/vehdebug.lpi) ;;
        # ./allochook/allochook.lpi) ;;
        # ./cepack/cepack.lpi) ;;
        # ./ceregreset/ceregreset.lpi) ;;
        # ./cheatengine.lpi) ;;
        # ./debuggertest/debuggertest.lpi) ;;
        # ./launcher/cheatengine.lpi) ;;
        # ./luaclient/luaclient.lpi) ;;
        # ./luaclient/testapp/luaclienttest.lpi) ;;
        # ./plugin/DebugEventLog/src/DebugEventLog.lpi) ;;
        # ./plugin/example/exampleplugin.lpi) ;;
        # ./plugin/forcedinjection/forcedinjection.lpi) ;;
        # ./sfx/level2/standalonephase2.lpi) ;;
        # ./speedhack/speedhack.lpi) ;;
        # ./speedhack/speedhacktest/speedhacktest.lpi) ;;
        # ./windowsrepair/windowsrepair.lpi) ;;
        # ./winhook/winhook.lpi) ;;
        ./cecore.lpi) ;;
        ./dbk32/Kernelmodule) ;;
        ./xmplayer/xmplayer.lpi) ;;
        unloader/Kernelmoduleunloader.lpi) ;;
        *)
            BUILD_COMMAND="$(node --input-type=module --eval '
import moduleFs from "fs";
(async function () {
    let data;
    let file = process.argv[1];
    data = await moduleFs.promises.readFile(file, "utf8");
    data = (/<BuildModes\b[\S\s]*?<\/BuildModes>/).exec(data)[0];
    data = data.matchAll(/Name="(.*?)"/g);
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
    switch (file) {
    case "./Tutorial/graphical/project1.lpi":
        data = "Release 32";
        break;
    }
    console.log(`lazbuild "${file}" --bm="${data}"`);
}());
' "$FILE")" # '
            printf "\n\n\n\n$BUILD_COMMAND\n"
            if [ "$npm_config_mode_dryrun" != 1 ]
            then
                eval "$BUILD_COMMAND"
            fi
            ;;
        esac
    done
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
    find "../../Cheat Engine" \
        | grep "\.dll$\|\.exe$" \
        | grep -v "\/bin\/" \
        | sort \
        | tr "\n" "\0" \
        | xargs -0 -I{} cp "{}" "branch-$GITHUB_BRANCH0/"
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
