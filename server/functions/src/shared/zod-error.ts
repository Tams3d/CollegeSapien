export const zodError = (err: any): unknown => err.issues ?? err.errors ?? err.message;
