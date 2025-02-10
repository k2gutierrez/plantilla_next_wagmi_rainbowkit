import React from 'react'
import OwnConnectButton from './screens/OwnConnectButton'
import Image from 'next/image'
import mingle from "../../../public/assets/bm6.png"

export default function Connect() {
    return (
        <div className="justify-items-center grid h-96 content-center mt-20">
            <p className='text-md md:text-xl font-[family-name:var(--font-hogfish)]'>BARREL PROGRAM</p>
            <Image src={mingle} alt='mingle' width={230} height={230} />
            <OwnConnectButton />
        </div>
    )
}
