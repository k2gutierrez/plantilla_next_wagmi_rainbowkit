'use client'
import { useAccount } from "wagmi";
import styles from "./profile.module.css"
import Navbar from "./components/Navbar";
import Connect from "./components/Connect";
import Welcome from "./components/Welcome";
import LFG from "./components/LFG";
import ClaimBlanco from "./components/ClaimBlanco";
import NoMingle from "./components/NoMingle";
import Panel from "./components/Panel";

export default function Home() {

  const { address, isConnected } = useAccount();

  return (
    <>
      <Navbar />
      <main className=" grid content-center justify-items-center text-black font-[family-name:var(--font-pressura)]">
        <Panel />
      </main>
    </>
  );
}
