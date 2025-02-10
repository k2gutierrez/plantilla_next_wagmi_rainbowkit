import React from 'react'
import Image from 'next/image'
import mingle from "../../../../public/assets/MinglesBarrel2.png"
import styles from "./profile.module.css"
import cls from "classnames"

export default function ClaimBlanco() {
    return (
        <div className="justify-items-center grid h-96 content-center mt-20">
            <p className='text-md md:text-xl font-[family-name:var(--font-hogfish)]'>THANK YOU HEROE!</p>
            <button className={cls(styles.backColor, 'p-2 rounded-xl text-white my-10')}>
                <p>
                    $CLAIM
                </p>
                <p>
                    BLANCO
                </p>
            </button>
            <Image src={mingle} alt='mingle' width={230} height={230} />
        </div>
    )
}
