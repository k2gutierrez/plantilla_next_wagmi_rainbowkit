import { useState } from "react";
import styles from "./profile.module.css"
import cls from "classnames"

export default function Modal2() {
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
                        <p className='mt-5 mb-8 text-sm mx-8 md:text-base font-[family-name:var(--font-pressura)]'>
                            $BLANCO ERC-20 has been MINTED
                        </p>
                        <p className='mb-5 text-sm mx-8 md:text-base font-[family-name:var(--font-pressura)]'>
                            Each token represents 750ml of Tequila Blanco
                        </p>
                        <p className='mb-5 text-sm mx-8 md:text-base font-[family-name:var(--font-pressura)]'>
                            4,167 liters have been gifted from our investor at DESTILERÍA GALERÍA
                        </p>

                        <div>
                            <button
                                onClick={closeModal}
                                className={cls(styles.backColor, "px-3 py-2 my-4 rounded hover:bg-red-600")}
                            >
                                NEXT
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
