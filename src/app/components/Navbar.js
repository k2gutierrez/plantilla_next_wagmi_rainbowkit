import React from 'react'
import Image from 'next/image'
import styles from "./profile.module.css"
import logo from "../../../public/assets/MinglesNewLogo.svg"
import cls from 'classnames'

export default function Navbar() {
    return (
        <nav className={cls(styles.backColor, "min-w-full p-1 md:p-1 gap-20 flex items-center justify-center text-black text-sm md:text-lg")}>
            <p className="me-1 md:me-8">BARREL PROGRAM</p>
            
            <button className="ms-1 md:ms-8" onClick={null}><Image src={logo} alt="Mingles Logo" width={70} height={70} /></button>
        </nav>
    )
}
