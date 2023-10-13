# Based on 22.04 LTS
FROM ubuntu:jammy

RUN apt-get -yq update && \
    apt-get -y upgrade && \
    apt-get -yq --no-install-suggests --no-install-recommends install \
    ocaml \
    menhir \
    llvm-14 \
    llvm-14-dev \
    m4 \
    git \
    ca-certificates \
    python3 \
    pkg-config \
    cmake \
    opam

RUN ln -s /usr/lib/llvm-14/bin/lli /usr/bin/lli
RUN ln -s /usr/lib/llvm-14/bin/llc /usr/bin/llc

RUN opam init -y --disable-sandboxing
RUN opam install -y \
    llvm.14.0.6 \
    ocamlfind \
    dune

WORKDIR /root

ENTRYPOINT ["opam", "exec", "--"]

CMD ["bash"]
