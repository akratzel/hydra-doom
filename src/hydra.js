import { Lucid, Blockfrost } from "lucid-cardano";

console.log("connecting to hydra head at ws://127.0.0.1:4001");

// Makeshift hydra client

const protocol = window.location.protocol == "https:" ? "wss:" : "ws:";
const conn = new WebSocket(protocol + "//127.0.0.1:4001?history=no");

conn.addEventListener("message", (e) => {
  const msg = JSON.parse(e.data);
  switch (msg.tag) {
    default:
      console.log("Hydra websocket", "Received", msg);
  }
});

async function getUTxO() {
  const res = await fetch("http://127.0.0.1:4001/snapshot/utxo");
  return res.json();
}

// Setup a lucid instance running against hydra

const lucid = await Lucid.new(
  new Blockfrost(
    "https://cardano-preprod.blockfrost.io/api/v0",
    "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
  ),
  "Preprod",
);

const privateKey = lucid.utils.generatePrivateKey();
console.log("Setting up an ad-hoc wallet", privateKey);
lucid.selectWalletFromPrivateKey(privateKey);

// Callbacks from forked doom-wasm

let latestCmd = { forwardMove: 0 };

export async function hydraSend(cmd) {
  console.log("encode and submit transaction for", cmd);

  const utxo = await getUTxO();
  console.log("spendable utxo", utxo);

  const txIn = Object.keys(utxo)[0];
  const [txHash, ixStr] = txIn.split("#");
  const txOut = utxo[txIn];
  console.log("selected txOut", txOut);
  const input = {
    txHash,
    outputIndex: Number.parseInt(ixStr),
    address: txOut.address,
    assets: txOut.value,
  };
  console.log("spending from", input);
  // FIXME: needs a custom provider to resolve UTxO against already known
  // const tx = await lucid
  //   .newTx()
  //   .collectFrom([input])
  //   .complete({ coinSelection: false });
  // console.log(tx);
}

export function hydraRecv() {
  const cmd = latestCmd;
  console.log("receive next decoded command from head", cmd);
  return cmd;
}
