import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";
import App from './app'
import localFont from "next/font/local";
import { Provider } from "jotai";

const pressura = localFont({ 
  src: '../../public/assets/GT-Pressura-Mono.otf',
  variable: '--font-pressura',
})
const hogfish = localFont({ 
  src: '../../public/assets/Hogfish DEMO.otf',
  variable: '--font-hogfish'
})

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata = {
  title: "Barrel Program",
  description: "Mingles staking Barrel Program on apechain",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body
        className={`${hogfish.variable} ${hogfish.variable} antialiased`}
      >
        <App>
          <Provider>
            {children}
          </Provider>
        </App>
      </body>
    </html>
  );
}
