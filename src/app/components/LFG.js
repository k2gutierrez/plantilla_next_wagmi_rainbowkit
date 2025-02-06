import React from 'react'
import Image from 'next/image'
import mingle from "../../../public/assets/bm11.png"
import styles from "./profile.module.css"
import cls from "classnames"

export default function LFG() {
    return (
        <div className="justify-items-center grid h-96 content-center mt-20">
            <p className='text-md md:text-xl font-[family-name:var(--font-hogfish)]'>ENJOY YOUR TEQUILA!</p>
            <Image src={mingle} alt='mingle' width={230} height={230} />
            <p className='text-sm md:text-md my-10 px-10 font-[family-name:var(--font-PRESSURA)]'>Stolen from the GIANT RAVEN and served in authentic BARREL style!</p>
            <button className={cls(styles.backColor, 'p-2 rounded-xl')}>
                LFG
            </button>
        </div>
    )
}
