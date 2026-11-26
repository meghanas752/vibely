import { Link } from 'react-router-dom'

export default function Home() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-rose-50 px-6 text-center">
      <h1 className="text-5xl font-bold text-rose-600">Vibely</h1>
      <p className="mt-3 text-lg text-gray-700">Find people who match your vibe.</p>
      <p className="mt-2 text-gray-500 max-w-md">
        Verified people. Real conversations. No endless swiping.
      </p>
      <Link
        to="/login"
        className="mt-8 rounded-full bg-rose-600 px-8 py-3 text-white font-semibold hover:bg-rose-700"
      >
        Get started
      </Link>
    </div>
  )
}