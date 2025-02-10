'use client'
import { useAccount } from "wagmi";
import styles from "./profile.module.css"
import Navbar from "./components/Navbar";
import Connect from "./components/Connect";
import Welcome from "./components/screens/Welcome";
import LFG from "./components/screens/LFG";
import ClaimBlanco from "./components/screens/ClaimBlanco";
import NoMingle from "./components/screens/NoMingle";
import Panel from "./components/screens/Panel";
import Modal1 from "./components/modals/Modal1";
import Modal2 from "./components/modals/Modal2";
import Modal3 from "./components/modals/Modal3";

export default function Home() {

  const { address, isConnected } = useAccount();

  return (
    <>
      <Navbar />
      <main className=" grid content-center justify-items-center text-black font-[family-name:var(--font-pressura)]">
        <Modal3 />
      </main>
    </>
  );
}
