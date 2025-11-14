import React from 'react'
import { Link } from 'react-router-dom'
import './Navbar.css'
import '../App.css'
export default function Navbar() {
  return (
    <div>
      {/* <h1>This is Navbar Component</h1> */}
      
        <Link to= "/">Home</Link>
        <Link to="/about">About</Link>
        <Link to="/contact">Contact</Link>
    </div>

  )
}
