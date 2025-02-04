'use client'
import Image from "next/image";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { useAccount } from "wagmi";
import { useAtom } from "jotai";
import { mingleIdAtom } from './store/atoms'

export default function Home() {

  const { address } = useAccount();
  const [mingleId, setMingleId] = useAtom(mingleIdAtom)

  const changeValue = () => {
    setMingleId((mingleId) => mingleId + 1)
  }

  return (
    <main>
      <ConnectButton />
      <p>{address}</p>
      <button onClick={changeValue} >change atom</button>
      <p>{mingleId}</p>
    </main>
  );
}
