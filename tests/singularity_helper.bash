CONTAINER_BINDINGS="-B $APP_DIR:$APP_DIR -B $JENKINS_HOME:$JENKINS_HOME"

setup() {
    if [ ! -f "${BATS_TEST_DIRNAME}/env_file" ]; then
        echo "Missing env_file"
        exit 100
    fi

    set -o allexport
    . "${BATS_TEST_DIRNAME}/env_file"
    set +o allexport

    if [ $(env | grep SINGULARITY_IMAGE_FILE | wc -c) -eq 0 ]; then
        echo Missing SINGULARITY_IMAGE_FILE environment variable
        exit 100
    fi
}

sexec() {
    singularity exec "${CONTAINER_BINDINGS} ${CONTAINER_OPTIONS}" "$SINGULARITY_IMAGE_FILE" "$@"
}

sshel() {
    singularity shell "${CONTAINER_BINDINGS} ${CONTAINER_OPTIONS}" "$SINGULARITY_IMAGE_FILE"
}

srun() {
    singularity run "${CONTAINER_BINDINGS} ${CONTAINER_OPTIONS}" "$SINGULARITY_IMAGE_FILE"
}