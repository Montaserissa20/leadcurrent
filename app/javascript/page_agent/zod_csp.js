// Evaluate before PageAgentCore creates Zod object schemas. Do not probe eval under our strict CSP.
import {z} from 'zod/v4'
z.config({jitless:true})
