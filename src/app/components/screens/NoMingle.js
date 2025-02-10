import React from 'react'
import Image from 'next/image'
import mingle from "../../../../public/assets/PFP_BabyMingles.png"
import eden from "../../../../public/assets/Magic-EdenLogo.webp"
import styles from "./profile.module.css"
import cls from "classnames"
import Link from 'next/link'

export default function NoMingle() {
    return (
        <div className="justify-items-center grid content-center mt-10">
            <Image src={mingle} alt='mingle' width={160} height={160} />
            <p className='mt-8 text-md md:text-xl font-[family-name:var(--font-hogfish)]'>NOT A HEROE YET?</p>
            <p className='my-8 text-md md:text-xl font-[family-name:var(--font-pressura)]'>Go find an UNCLAIMED Mingle:Aped</p>
            <Link href={"https://magiceden.io/collections/apechain/0x6579cfd742d8982a7cdc4c00102d3087f6c6dd8e"}>
                <Image src={eden} alt='mingle' width={80} height={80} className='rounded-full' />
            </Link>
            <p className='mt-10 text-sm md:text-lg font-[family-name:var(--font-hogfish)]'>ENTER MINGLE ID</p>
            <div className='flex h-8 mb-6 mt-4'>
                <input type='number' className='block w-32 min-w-0 grow py-1.5 pr-3 pl-1 border border-red-600 text-base text-gray-900 placeholder:text-gray-400 focus:outline-none sm:text-sm/6' />
                <button className={cls(styles.backColor, 'ms-2 w-14 p-1 rounded-lg text-white text-sm md:text-base')}>
                    CHECK
                </button>
            </div>
            <p className='text-md md:text-xl text-blue-600 font-[family-name:var(--font-pressura)]'>CLAIMED</p>
            <p className='text-md md:text-xl text-red-600 font-[family-name:var(--font-pressura)]'>UNCLAIMED</p>
        </div>
    )
}
