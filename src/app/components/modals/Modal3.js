import { useState } from "react";
import styles from "./profile.module.css"
import cls from "classnames"

export default function Modal3() {
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
                        <p className='text-base md:text-xl font-[family-name:var(--font-hogfish)]'>
                            CHEERS!
                        </p>
                        <p className='mt-5 mb-5 text-xs mx-5 md:text-base font-[family-name:var(--font-pressura)]'>
                            $Blanco Tequila takes 3 months to become $REPOSADO Tequila
                        </p>
                        <p className='mb-5 text-xs mx-5 md:text-base font-[family-name:var(--font-pressura)]'>
                            This is the Tequila AGING process.
                        </p>
                        <p className='mb-5 text-xs mx-5 md:text-base font-[family-name:var(--font-pressura)]'>
                            After this period holders can claim the REPOSADO BOTTLES, APE or keep AGING their Tequila into an AÑEJO
                        </p>

                        <div>
                            <button
                                onClick={closeModal}
                                className={cls(styles.backColor, "px-3 py-2 my-4 rounded hover:bg-red-600")}
                            >
                                MY CAVA
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
