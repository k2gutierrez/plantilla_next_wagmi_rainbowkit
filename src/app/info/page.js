'use client'
import React from 'react'
import { useAtom } from 'jotai'
import { mingleIdAtom } from '../store/atoms'

export default function info() {

    const [mingleId, setMingleId] = useAtom(mingleIdAtom)

  return (
    <div>{mingleId}</div>
  )
}
