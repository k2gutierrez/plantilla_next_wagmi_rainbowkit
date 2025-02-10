import { useState } from "react";
import styles from "./profile.module.css"
import cls from "classnames"
import Link from "next/link";

export default function Modal1() {
    const [isOpen, setIsOpen] = useState(false);

    const openModal = () => setIsOpen(true);
    const closeModal = () => setIsOpen(false);

    return (
        <div className="flex items-center justify-center bg-gray-100">
            <button
                onClick={openModal}
                className={cls(styles.backColor, "px-4 py-2 text-white rounded hover:bg-red-600")}
            >
                Abrir Modal
            </button>

            {isOpen && (
                <div className="fixed inset-0 z-50 flex items-center text-center justify-center bg-black bg-opacity-50">
                    <div className={cls(styles.bg, "mx-8 p-6 rounded-lg shadow-lg w-96 transform transition-transform scale-95 hover:scale-100")}>
                        <p className='text-md md:text-xl font-[family-name:var(--font-hogfish)]'>
                            HERO SAVED
                        </p>
                        <p className='my-3 text-xs md:text-md font-[family-name:var(--font-pressura)]'>
                            56 Mingles
                        </p>
                        <p className='my-3 text-md md:text-xl font-[family-name:var(--font-hogfish)]'>
                            HERO CAN CLAIM
                        </p>
                        <p className='text-xs md:text-md font-[family-name:var(--font-pressura)]'>
                            56 Bottles
                        </p>
                        <div>
                            <button
                                onClick={closeModal}
                                className={cls(styles.backColor, "px-3 py-2 my-4 rounded hover:bg-red-600")}
                            >
                                <p>CLAIM</p>
                                <p>$BLANCO</p>
                            </button>
                        </div>
                        <Link href={"/"} classNames="text-sm md:text-base">Disclaimer</Link>
                    </div>
                </div>
            )}
        </div>
    );
}
